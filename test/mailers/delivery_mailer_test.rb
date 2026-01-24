# frozen_string_literal: true

require "test_helper"

class DeliveryMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:owner)
    @delivery = deliveries(:failed_delivery)
    @destination = @delivery.destination
  end

  test "failure_notification sends email to user" do
    email = DeliveryMailer.failure_notification(user: @user, delivery: @delivery)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@user.email], email.to
    assert_equal "Webhook delivery failed: #{@destination.name}", email.subject
  end

  test "failure_notification includes destination name in body" do
    email = DeliveryMailer.failure_notification(user: @user, delivery: @delivery)

    assert_match @destination.name, email.body.encoded
  end

  test "failure_notification includes destination URL in body" do
    email = DeliveryMailer.failure_notification(user: @user, delivery: @delivery)

    assert_match @destination.url, email.body.encoded
  end

  test "failure_notification includes attempt count in body" do
    email = DeliveryMailer.failure_notification(user: @user, delivery: @delivery)

    assert_match "#{@delivery.attempt_count} / #{@delivery.max_attempts}", email.body.encoded
  end

  test "failure_notification includes user first name" do
    email = DeliveryMailer.failure_notification(user: @user, delivery: @delivery)

    assert_match @user.first_name, email.body.encoded
  end

  test "failure_notification includes link to delivery page" do
    email = DeliveryMailer.failure_notification(user: @user, delivery: @delivery)

    assert_match %r{/en/deliveries/#{@delivery.id}}, email.body.encoded
  end

  test "failure_notification includes link to profile settings" do
    email = DeliveryMailer.failure_notification(user: @user, delivery: @delivery)

    assert_match %r{/en/edit}, email.body.encoded
  end

  test "failure_notification has both html and text parts" do
    email = DeliveryMailer.failure_notification(user: @user, delivery: @delivery)

    assert email.multipart?
    assert email.html_part.present?
    assert email.text_part.present?
  end
end
