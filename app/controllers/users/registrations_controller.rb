# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include TurnstileVerification

  before_action :configure_sign_up_params, only: [:create]
  before_action :verify_turnstile, only: [:create]

  def create
    # Extract organization_name before building resource
    organization_name = params[:user]&.delete(:organization_name)

    build_resource(sign_up_params)

    ActiveRecord::Base.transaction do
      resource.save!

      # Create organization from the form
      organization = Organization.create!(name: organization_name)

      # Create membership with owner role
      Membership.create!(user: resource, organization: organization, role: :owner)
    end

    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  rescue ActiveRecord::RecordInvalid => e
    clean_up_passwords resource
    set_minimum_password_length

    # Add organization name error if it was the issue
    if e.message.include?("Name")
      resource.errors.add(:organization_name, "can't be blank")
    end

    respond_with resource
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :organization_name, :"cf-turnstile-response"])
  end

  def prepare_resource_for_turnstile_error
    # Exclude organization_name since it's not a User attribute
    user_params = sign_up_params.except(:organization_name)
    build_resource(user_params)
    set_minimum_password_length
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end

  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end
end
