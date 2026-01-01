# frozen_string_literal: true

class SignatureVerifier
  class << self
    # Stripe: uses Stripe-Signature header with timestamp
    # Format: t=timestamp,v1=signature
    def verify_stripe(request, secret)
      return true if secret.blank?

      signature = request.headers["Stripe-Signature"]
      return false if signature.blank?

      payload = request.raw_post

      begin
        # Parse the signature header
        parts = signature.split(",").map { |p| p.split("=", 2) }.to_h
        timestamp = parts["t"]
        signatures = parts.select { |k, _| k.start_with?("v1") }.values

        return false if timestamp.blank? || signatures.empty?

        # Build signed payload
        signed_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

        # Check if any signature matches
        signatures.any? { |sig| secure_compare(sig, expected_signature) }
      rescue => e
        Rails.logger.error("Stripe signature verification failed: #{e.message}")
        false
      end
    end

    # Shopify: uses X-Shopify-Hmac-SHA256 header (Base64 encoded)
    def verify_shopify(request, secret)
      return true if secret.blank?

      signature = request.headers["X-Shopify-Hmac-SHA256"]
      return false if signature.blank?

      payload = request.raw_post

      expected = Base64.strict_encode64(
        OpenSSL::HMAC.digest("SHA256", secret, payload)
      )

      secure_compare(signature, expected)
    end

    # GitHub: uses X-Hub-Signature-256 header
    # Format: sha256=hexdigest
    def verify_github(request, secret)
      return true if secret.blank?

      signature = request.headers["X-Hub-Signature-256"]
      return false if signature.blank?

      payload = request.raw_post

      expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, payload)

      secure_compare(signature, expected)
    end

    # Generic HMAC-SHA256 verification
    # Checks common header names: X-Signature, X-Webhook-Signature, X-Hmac-Signature
    def verify_hmac(request, secret)
      return true if secret.blank?

      payload = request.raw_post

      # Try common signature header names
      signature_headers = [
        "X-Signature",
        "X-Webhook-Signature",
        "X-Hmac-Signature",
        "X-Hub-Signature-256",
        "X-Signature-256"
      ]

      signature = signature_headers.filter_map { |h| request.headers[h] }.first
      return false if signature.blank?

      # Handle different signature formats
      expected_hex = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
      expected_base64 = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, payload))

      # Check various formats
      secure_compare(signature, expected_hex) ||
        secure_compare(signature, "sha256=#{expected_hex}") ||
        secure_compare(signature, expected_base64)
    end

    private

    def secure_compare(a, b)
      ActiveSupport::SecurityUtils.secure_compare(a.to_s, b.to_s)
    end
  end
end
