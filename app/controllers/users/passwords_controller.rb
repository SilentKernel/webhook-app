# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  include TurnstileVerification

  before_action :verify_turnstile, only: [:create]

  protected

  def prepare_resource_for_turnstile_error
    self.resource = resource_class.new(resource_params)
  end

  private

  def resource_params
    params.require(:user).permit(:email, :"cf-turnstile-response")
  end
end
