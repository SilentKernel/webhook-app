# frozen_string_literal: true

class SendDeliveryFailureNotificationJob < ApplicationJob
  queue_as :default

  def perform(delivery_id)
    delivery = Delivery.find_by(id: delivery_id)
    return unless delivery

    destination = delivery.destination
    return unless destination

    destination.notification_subscribers.find_each do |user|
      next unless user.can_receive_failure_email?

      DeliveryMailer.failure_notification(user: user, delivery: delivery).deliver_later
      user.update_column(:last_failure_email_sent_at, Time.current)
    end
  end
end
