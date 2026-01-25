# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @organization = invitation.organization
    @accept_url = invitation_url(@invitation.token, locale: I18n.locale)

    mail(
      to: @invitation.email,
      subject: "HookStack.io - You've been invited to join #{@organization.name}"
    )
  end
end
