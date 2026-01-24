# frozen_string_literal: true

require "test_helper"

class TurnstileServiceTest < ActiveSupport::TestCase
  VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  test "returns success hash for valid token" do
    stub_request(:post, VERIFY_URL)
      .to_return(status: 200, body: {
        success: true,
        challenge_ts: "2024-01-01T00:00:00Z",
        hostname: "example.com"
      }.to_json)

    result = TurnstileService.verify(token: "valid_token", remote_ip: "127.0.0.1")

    assert result[:success]
    assert_empty result[:error_codes]
    assert_equal "2024-01-01T00:00:00Z", result[:challenge_ts]
    assert_equal "example.com", result[:hostname]
  end

  test "returns failure hash for invalid token" do
    stub_request(:post, VERIFY_URL)
      .to_return(status: 200, body: {
        success: false,
        "error-codes": ["invalid-input-response"]
      }.to_json)

    result = TurnstileService.verify(token: "invalid_token", remote_ip: "127.0.0.1")

    assert_not result[:success]
    assert_includes result[:error_codes], "invalid-input-response"
  end

  test "returns failure hash for blank token" do
    result = TurnstileService.verify(token: "", remote_ip: "127.0.0.1")

    assert_not result[:success]
    assert_includes result[:error_codes], "missing-input-response"
  end

  test "returns failure hash for nil token" do
    result = TurnstileService.verify(token: nil, remote_ip: "127.0.0.1")

    assert_not result[:success]
    assert_includes result[:error_codes], "missing-input-response"
  end

  test "returns failure hash on timeout" do
    stub_request(:post, VERIFY_URL).to_timeout

    result = TurnstileService.verify(token: "test_token", remote_ip: "127.0.0.1")

    assert_not result[:success]
    assert_includes result[:error_codes], "timeout-or-duplicate"
  end

  test "returns failure hash on connection failure" do
    stub_request(:post, VERIFY_URL).to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    result = TurnstileService.verify(token: "test_token", remote_ip: "127.0.0.1")

    assert_not result[:success]
    assert_includes result[:error_codes], "timeout-or-duplicate"
  end

  test "returns failure hash on invalid JSON response" do
    stub_request(:post, VERIFY_URL)
      .to_return(status: 200, body: "not valid json")

    result = TurnstileService.verify(token: "test_token", remote_ip: "127.0.0.1")

    assert_not result[:success]
    assert_includes result[:error_codes], "internal-error"
  end

  test "sends correct parameters to Cloudflare" do
    stub = stub_request(:post, VERIFY_URL)
      .with(body: hash_including(
        "response" => "test_token",
        "remoteip" => "192.168.1.1"
      ))
      .to_return(status: 200, body: { success: true }.to_json)

    TurnstileService.verify(token: "test_token", remote_ip: "192.168.1.1")

    assert_requested(stub)
  end

  test "remote_ip is optional" do
    stub = stub_request(:post, VERIFY_URL)
      .with { |req| !req.body.include?("remoteip") }
      .to_return(status: 200, body: { success: true }.to_json)

    TurnstileService.verify(token: "test_token")

    assert_requested(stub)
  end

  test "site_key returns value from credentials" do
    assert_equal Rails.application.credentials.dig(:turnstile, :site_key), TurnstileService.site_key
  end

  test "secret_key returns value from credentials" do
    assert_equal Rails.application.credentials.dig(:turnstile, :secret_key), TurnstileService.secret_key
  end

  test "instance verify method works the same as class method" do
    stub_request(:post, VERIFY_URL)
      .to_return(status: 200, body: { success: true }.to_json)

    service = TurnstileService.new
    result = service.verify(token: "test_token", remote_ip: "127.0.0.1")

    assert result[:success]
  end
end
