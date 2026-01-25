# frozen_string_literal: true

class DeliveryMailer < ApplicationMailer
  def failure_notification(user:, delivery:)
    @user = user
    @delivery = delivery
    @destination = delivery.destination
    @event = delivery.event

    mail(
      to: @user.email,
      subject: "HookStack.io - Heads up! Delivery to #{@destination.name} failed"
    )
  end
end
