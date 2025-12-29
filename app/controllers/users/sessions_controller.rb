# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # Override to clear organization session on login
  def create
    super do |resource|
      # Clear previous organization session to start fresh
      session.delete(:organization_id)
    end
  end
end
