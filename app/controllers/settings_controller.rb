# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization
  before_action :require_owner

  def show
    @organization = current_organization
  end

  def update
    @organization = current_organization

    if @organization.update(organization_params)
      redirect_to settings_path, notice: "Organization settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :timezone)
  end
end
