# frozen_string_literal: true

require "test_helper"

class SendInvitationEmailJobTest < ActiveJob::TestCase
  test "sends invitation email for valid pending invitation" do
    invitation = invitations(:pending)

    assert_emails 1 do
      SendInvitationEmailJob.perform_now(invitation.id)
    end
  end

  test "does not send email for non-existent invitation" do
    assert_emails 0 do
      SendInvitationEmailJob.perform_now(999999)
    end
  end

  test "does not send email for accepted invitation" do
    invitation = invitations(:accepted)

    assert_emails 0 do
      SendInvitationEmailJob.perform_now(invitation.id)
    end
  end

  test "does not send email for expired invitation" do
    invitation = invitations(:expired)

    assert_emails 0 do
      SendInvitationEmailJob.perform_now(invitation.id)
    end
  end

  test "job is enqueued to default queue" do
    assert_equal "default", SendInvitationEmailJob.new.queue_name
  end
end
