# frozen_string_literal: true

class ProcessWebhookJob < ApplicationJob
  queue_as :webhooks

  def perform(event_id)
    event = Event.find_by(id: event_id)
    return unless event

    source = event.source
    return unless source.active?

    # Find all active connections for this source
    connections = source.connections.active.includes(:destination).ordered

    connections.each do |connection|
      # Skip if destination is not active
      next unless connection.destination.status_active?

      # Apply filter rules
      next unless connection.passes_filters?(event)

      # Create delivery
      delivery = event.deliveries.create!(
        connection: connection,
        destination: connection.destination,
        status: :queued,
        max_attempts: Delivery::DEFAULT_MAX_ATTEMPTS
      )

      # Check for delay rule
      if connection.delay_seconds > 0
        DeliverWebhookJob.set(wait: connection.delay_seconds.seconds).perform_later(delivery.id)
      else
        DeliverWebhookJob.perform_later(delivery.id)
      end
    end
  end
end
