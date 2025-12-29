# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization

  def index
    @organization = current_organization
    @membership = current_membership
  end
end
