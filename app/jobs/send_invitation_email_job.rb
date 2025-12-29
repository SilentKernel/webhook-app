# frozen_string_literal: true

class SendInvitationEmailJob < ApplicationJob
  queue_as :default

  def perform(invitation_id)
    invitation = Invitation.find_by(id: invitation_id)
    return unless invitation
    return if invitation.accepted? || invitation.expired?

    InvitationMailer.invite(invitation).deliver_now
  end
end
