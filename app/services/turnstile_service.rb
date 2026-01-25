# frozen_string_literal: true

# Service for verifying Cloudflare Turnstile tokens.
#
# Turnstile is a CAPTCHA alternative that verifies users are human.
# This service calls the Cloudflare siteverify API to validate tokens.
#
# @example Verifying a token
#   result = TurnstileService.verify(token: params["cf-turnstile-response"], remote_ip: request.remote_ip)
#   if result[:success]
#     # User verified
#   else
#     # Verification failed, check result[:error_codes]
#   end
#
# Configuration: Store keys in Rails credentials under :turnstile
#   turnstile:
#     site_key: "your-site-key"
#     secret_key: "your-secret-key"
#
class TurnstileService
  VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  # Verifies a Turnstile token with Cloudflare's API.
  #
  # @param token [String] The cf-turnstile-response token from the form
  # @param remote_ip [String, nil] The user's IP address (optional but recommended)
  # @return [Hash] Result hash with :success, :error_codes, :challenge_ts, :hostname, :action, :cdata
  def self.verify(token:, remote_ip: nil)
    new.verify(token: token, remote_ip: remote_ip)
  end

  def verify(token:, remote_ip: nil)
    return failure_response(["missing-input-response"]) if token.blank?

    response = Faraday.post(VERIFY_URL) do |req|
      req.options.timeout = 10
      req.options.open_timeout = 5
      req.body = {
        secret: secret_key,
        response: token,
        remoteip: remote_ip
      }.compact
    end

    parse_response(response.body)
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    Rails.logger.error("Turnstile verification network error: #{e.message}")
    failure_response(["timeout-or-duplicate"])
  rescue JSON::ParserError => e
    Rails.logger.error("Turnstile verification JSON parse error: #{e.message}")
    failure_response(["internal-error"])
  end

  # Returns the site key for the Turnstile widget.
  def self.site_key
    Rails.application.credentials.dig(:turnstile, :site_key)
  end

  # Returns the secret key for API verification.
  def self.secret_key
    Rails.application.credentials.dig(:turnstile, :secret_key)
  end

  private

  def secret_key
    self.class.secret_key
  end

  def parse_response(body)
    data = JSON.parse(body)

    {
      success: data["success"] == true,
      error_codes: data["error-codes"] || [],
      challenge_ts: data["challenge_ts"],
      hostname: data["hostname"],
      action: data["action"],
      cdata: data["cdata"]
    }
  end

  def failure_response(error_codes)
    {
      success: false,
      error_codes: error_codes,
      challenge_ts: nil,
      hostname: nil,
      action: nil,
      cdata: nil
    }
  end
end
