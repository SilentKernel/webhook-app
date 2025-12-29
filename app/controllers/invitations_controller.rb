# frozen_string_literal: true

class InvitationsController < ApplicationController
  before_action :set_invitation
  before_action :check_invitation_validity, except: [:show]

  def show
    if @invitation.accepted?
      flash[:notice] = "This invitation has already been accepted."
      redirect_to_appropriate_path
      return
    end

    if @invitation.expired?
      flash[:alert] = "This invitation has expired."
      redirect_to new_user_session_path
      return
    end
  end

  def accept
    if user_signed_in?
      if current_user.organizations.include?(@invitation.organization)
        flash[:notice] = "You are already a member of this organization."
        redirect_to dashboard_path
        return
      end

      if @invitation.accept!(current_user)
        session[:organization_id] = @invitation.organization_id
        redirect_to dashboard_path, notice: "You have joined #{@invitation.organization.name}!"
      else
        redirect_to invitation_path(@invitation.token), alert: "Unable to accept invitation. Please try again."
      end
    else
      # Store invitation token in session for after signup/login
      session[:pending_invitation_token] = @invitation.token
      redirect_to new_user_session_path, notice: "Please log in or sign up to accept this invitation."
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Invitation not found."
    redirect_to new_user_session_path
  end

  def check_invitation_validity
    if @invitation.accepted?
      flash[:notice] = "This invitation has already been accepted."
      redirect_to_appropriate_path
    elsif @invitation.expired?
      flash[:alert] = "This invitation has expired."
      redirect_to new_user_session_path
    end
  end

  def redirect_to_appropriate_path
    if user_signed_in?
      redirect_to dashboard_path
    else
      redirect_to new_user_session_path
    end
  end
end
