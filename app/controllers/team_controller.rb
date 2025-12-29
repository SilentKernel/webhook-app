# frozen_string_literal: true

class TeamController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization
  before_action :require_admin_or_owner, except: [:index]
  before_action :set_membership, only: [:destroy, :update_role]

  def index
    @memberships = current_organization.memberships.includes(:user).order(created_at: :asc)
    @pending_invitations = current_organization.invitations.pending.includes(:invited_by).order(created_at: :desc)
  end

  def new_invite
    @invitation = current_organization.invitations.new
  end

  def create_invite
    @invitation = current_organization.invitations.new(invitation_params)
    @invitation.invited_by = current_user

    if @invitation.save
      SendInvitationEmailJob.perform_later(@invitation.id)
      redirect_to team_index_path, notice: "Invitation sent to #{@invitation.email}."
    else
      render :new_invite, status: :unprocessable_entity
    end
  end

  def destroy
    if @membership.owner?
      redirect_to team_index_path, alert: "Cannot remove the organization owner."
      return
    end

    if @membership.user == current_user
      redirect_to team_index_path, alert: "You cannot remove yourself from the team."
      return
    end

    @membership.destroy
    respond_to do |format|
      format.html { redirect_to team_index_path, notice: "Team member removed." }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@membership) }
    end
  end

  def update_role
    unless owner?
      redirect_to team_index_path, alert: "Only the owner can change roles."
      return
    end

    if @membership.user == current_user
      redirect_to team_index_path, alert: "You cannot change your own role."
      return
    end

    if @membership.owner?
      redirect_to team_index_path, alert: "Cannot change the owner's role."
      return
    end

    new_role = params[:role]
    unless %w[member admin].include?(new_role)
      redirect_to team_index_path, alert: "Invalid role."
      return
    end

    @membership.update!(role: new_role)
    redirect_to team_index_path, notice: "Role updated successfully."
  end

  private

  def set_membership
    @membership = current_organization.memberships.find(params[:id])
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end
end
