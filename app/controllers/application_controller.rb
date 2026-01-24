# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :set_timezone, if: :current_organization

  helper_method :current_organization, :owner?, :admin_or_owner?, :current_membership

  protected

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def current_organization
    return @current_organization if defined?(@current_organization)

    @current_organization = if session[:organization_id]
      current_user&.organizations&.find_by(id: session[:organization_id])
    end

    @current_organization ||= current_user&.organizations&.first
    session[:organization_id] = @current_organization&.id
    @current_organization
  end

  def current_membership
    return @current_membership if defined?(@current_membership)
    return nil unless current_user && current_organization

    @current_membership = current_user.memberships.find_by(organization: current_organization)
  end

  def switch_organization(organization)
    if current_user.organizations.include?(organization)
      session[:organization_id] = organization.id
      @current_organization = organization
      @current_membership = nil
    end
  end

  def owner?
    current_membership&.owner?
  end

  def admin_or_owner?
    current_membership&.owner? || current_membership&.admin?
  end

  def require_owner
    unless owner?
      flash[:alert] = "You must be an owner to perform this action."
      redirect_to dashboard_path
    end
  end

  def require_admin_or_owner
    unless admin_or_owner?
      flash[:alert] = "You must be an admin or owner to perform this action."
      redirect_to dashboard_path
    end
  end

  def require_organization
    unless current_organization
      flash[:alert] = "You must belong to an organization."
      redirect_to new_user_registration_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :organization_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboard_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def set_timezone
    Time.use_zone(current_organization.timezone) { yield }
  end
end
