# frozen_string_literal: true

# Provides Turnstile verification for controllers.
#
# Include this concern in controllers that need bot verification.
# The including controller must implement #prepare_resource_for_turnstile_error.
#
# @example Usage in a controller
#   class RegistrationsController < ApplicationController
#     include TurnstileVerification
#     before_action :verify_turnstile, only: :create
#
#     private
#
#     def prepare_resource_for_turnstile_error
#       @resource = build_resource(sign_up_params)
#     end
#   end
#
module TurnstileVerification
  extend ActiveSupport::Concern

  # Cloudflare Turnstile error codes mapped to user-friendly messages.
  ERROR_MESSAGES = {
    "missing-input-secret" => "Verification configuration error. Please contact support.",
    "invalid-input-secret" => "Verification configuration error. Please contact support.",
    "missing-input-response" => "Please complete the verification challenge.",
    "invalid-input-response" => "Verification failed. Please try again.",
    "bad-request" => "Verification request error. Please try again.",
    "timeout-or-duplicate" => "Verification expired. Please try again.",
    "internal-error" => "Verification service error. Please try again."
  }.freeze

  DEFAULT_ERROR_MESSAGE = "Bot verification failed. Please try again."

  private

  def verify_turnstile
    token = params["cf-turnstile-response"]
    result = TurnstileService.verify(token: token, remote_ip: request.remote_ip)

    unless result[:success]
      flash.now[:alert] = turnstile_error_message(result[:error_codes])
      prepare_resource_for_turnstile_error
      render :new, status: :unprocessable_entity
    end
  end

  # Returns a user-friendly error message based on Turnstile error codes.
  #
  # @param error_codes [Array<String>] Error codes from Turnstile API
  # @return [String] User-friendly error message
  def turnstile_error_message(error_codes)
    return DEFAULT_ERROR_MESSAGE if error_codes.blank?

    # Use the first error code that has a mapped message
    error_codes.each do |code|
      return ERROR_MESSAGES[code] if ERROR_MESSAGES.key?(code)
    end

    DEFAULT_ERROR_MESSAGE
  end

  # Subclasses must implement this to set up instance variables for re-rendering.
  # This method is called when Turnstile verification fails, before rendering :new.
  def prepare_resource_for_turnstile_error
    raise NotImplementedError, "#{self.class} must implement #prepare_resource_for_turnstile_error"
  end
end
