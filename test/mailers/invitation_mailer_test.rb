# frozen_string_literal: true

require "test_helper"

class InvitationMailerTest < ActionMailer::TestCase
  test "invite email is sent with correct attributes" do
    invitation = invitations(:pending)

    email = InvitationMailer.invite(invitation)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ invitation.email ], email.to
    assert_match invitation.organization.name, email.subject
    assert_match "invited", email.subject.downcase
  end

  test "invite email contains organization name" do
    invitation = invitations(:pending)

    email = InvitationMailer.invite(invitation)

    assert_match invitation.organization.name, email.body.encoded
  end

  test "invite email contains invitation role" do
    invitation = invitations(:pending)

    email = InvitationMailer.invite(invitation)

    assert_match invitation.role, email.body.encoded
  end

  test "invite email contains accept link" do
    invitation = invitations(:pending)

    email = InvitationMailer.invite(invitation)

    assert_match invitation.token, email.body.encoded
  end

  test "invite email includes inviter name when present" do
    invitation = invitations(:pending)

    email = InvitationMailer.invite(invitation)

    assert_match invitation.invited_by.full_name, email.body.encoded
  end
end
