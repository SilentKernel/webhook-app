# frozen_string_literal: true

require "test_helper"

class SendDeliveryFailureNotificationJobTest < ActiveJob::TestCase
  setup do
    @delivery = deliveries(:failed_delivery)
    @destination = @delivery.destination
    @subscription = destination_notification_subscriptions(:owner_production_api)
    @user = @subscription.user
    @user.update!(last_failure_email_sent_at: nil)
  end

  test "sends email to all subscribers" do
    assert_enqueued_emails 2 do
      SendDeliveryFailureNotificationJob.perform_now(@delivery.id)
    end
  end

  test "updates last_failure_email_sent_at for each subscriber" do
    freeze_time do
      SendDeliveryFailureNotificationJob.perform_now(@delivery.id)

      @user.reload
      assert_equal Time.current, @user.last_failure_email_sent_at
    end
  end

  test "does not send email to unconfirmed users" do
    @user.update!(confirmed_at: nil)

    assert_no_enqueued_emails do
      # This should only send to the admin user (the second subscriber)
      # since owner is now unconfirmed
    end

    # Actually test the logic properly
    assert_enqueued_emails 1 do
      SendDeliveryFailureNotificationJob.perform_now(@delivery.id)
    end
  end

  test "does not send email to users within rate limit window" do
    @user.update!(last_failure_email_sent_at: 5.minutes.ago)

    # Only admin should receive email since owner is rate limited
    assert_enqueued_emails 1 do
      SendDeliveryFailureNotificationJob.perform_now(@delivery.id)
    end
  end

  test "sends email to users after rate limit expires" do
    @user.update!(last_failure_email_sent_at: 11.minutes.ago)

    assert_enqueued_emails 2 do
      SendDeliveryFailureNotificationJob.perform_now(@delivery.id)
    end
  end

  test "does nothing for non-existent delivery" do
    assert_no_enqueued_emails do
      SendDeliveryFailureNotificationJob.perform_now(-1)
    end
  end

  test "does nothing when destination has no subscribers" do
    # Use disabled_destination which has no subscribers
    delivery = deliveries(:pending_delivery)
    delivery.update!(destination: destinations(:disabled_destination))

    assert_no_enqueued_emails do
      SendDeliveryFailureNotificationJob.perform_now(delivery.id)
    end
  end
end
