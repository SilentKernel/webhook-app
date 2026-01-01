# frozen_string_literal: true

require "test_helper"

class SignatureVerifierTest < ActiveSupport::TestCase
  test "verifies stripe signature" do
    secret = "whsec_test_secret"
    payload = '{"id":"evt_123"}'
    timestamp = Time.now.to_i

    signed_payload = "#{timestamp}.#{payload}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

    request = mock_request(
      payload,
      { "Stripe-Signature" => "t=#{timestamp},v1=#{signature}" }
    )

    assert SignatureVerifier.verify_stripe(request, secret)
  end

  test "rejects invalid stripe signature" do
    secret = "whsec_test_secret"
    payload = '{"id":"evt_123"}'

    request = mock_request(
      payload,
      { "Stripe-Signature" => "t=123,v1=invalid_signature" }
    )

    assert_not SignatureVerifier.verify_stripe(request, secret)
  end

  test "rejects missing stripe signature header" do
    secret = "whsec_test_secret"
    payload = '{"id":"evt_123"}'

    request = mock_request(payload, {})

    assert_not SignatureVerifier.verify_stripe(request, secret)
  end

  test "verifies github signature" do
    secret = "github_secret"
    payload = '{"action":"opened"}'

    signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, payload)

    request = mock_request(
      payload,
      { "X-Hub-Signature-256" => signature }
    )

    assert SignatureVerifier.verify_github(request, secret)
  end

  test "rejects invalid github signature" do
    secret = "github_secret"
    payload = '{"action":"opened"}'

    request = mock_request(
      payload,
      { "X-Hub-Signature-256" => "sha256=invalid_signature" }
    )

    assert_not SignatureVerifier.verify_github(request, secret)
  end

  test "verifies shopify signature" do
    secret = "shopify_secret"
    payload = '{"id":"123"}'

    signature = Base64.strict_encode64(
      OpenSSL::HMAC.digest("SHA256", secret, payload)
    )

    request = mock_request(
      payload,
      { "X-Shopify-Hmac-SHA256" => signature }
    )

    assert SignatureVerifier.verify_shopify(request, secret)
  end

  test "rejects invalid shopify signature" do
    secret = "shopify_secret"
    payload = '{"id":"123"}'

    request = mock_request(
      payload,
      { "X-Shopify-Hmac-SHA256" => "invalid_base64_signature" }
    )

    assert_not SignatureVerifier.verify_shopify(request, secret)
  end

  test "verifies hmac signature with hex format" do
    secret = "hmac_secret"
    payload = '{"data":"test"}'

    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)

    request = mock_request(
      payload,
      { "X-Signature" => signature }
    )

    assert SignatureVerifier.verify_hmac(request, secret)
  end

  test "verifies hmac signature with sha256= prefix" do
    secret = "hmac_secret"
    payload = '{"data":"test"}'

    signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, payload)

    request = mock_request(
      payload,
      { "X-Webhook-Signature" => signature }
    )

    assert SignatureVerifier.verify_hmac(request, secret)
  end

  test "verifies hmac signature with base64 format" do
    secret = "hmac_secret"
    payload = '{"data":"test"}'

    signature = Base64.strict_encode64(
      OpenSSL::HMAC.digest("SHA256", secret, payload)
    )

    request = mock_request(
      payload,
      { "X-Hmac-Signature" => signature }
    )

    assert SignatureVerifier.verify_hmac(request, secret)
  end

  test "returns true when no secret configured for stripe" do
    request = mock_request('{"test":true}', {})

    assert SignatureVerifier.verify_stripe(request, nil)
    assert SignatureVerifier.verify_stripe(request, "")
  end

  test "returns true when no secret configured for github" do
    request = mock_request('{"test":true}', {})

    assert SignatureVerifier.verify_github(request, nil)
    assert SignatureVerifier.verify_github(request, "")
  end

  test "returns true when no secret configured for shopify" do
    request = mock_request('{"test":true}', {})

    assert SignatureVerifier.verify_shopify(request, nil)
    assert SignatureVerifier.verify_shopify(request, "")
  end

  test "returns true when no secret configured for hmac" do
    request = mock_request('{"test":true}', {})

    assert SignatureVerifier.verify_hmac(request, nil)
    assert SignatureVerifier.verify_hmac(request, "")
  end

  private

  def mock_request(body, headers)
    MockRequest.new(body, headers)
  end

  class MockRequest
    attr_reader :raw_post

    def initialize(body, headers)
      @raw_post = body
      @headers = MockHeaders.new(headers)
    end

    def headers
      @headers
    end
  end

  class MockHeaders
    def initialize(hash)
      @hash = hash
    end

    def [](key)
      @hash[key]
    end
  end
end
