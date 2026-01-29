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
      next unless passes_filters?(event, connection)

      # Create delivery
      delivery = event.deliveries.create!(
        connection: connection,
        destination: connection.destination,
        status: :queued,
        max_attempts: Delivery::DEFAULT_MAX_ATTEMPTS
      )

      # Check for delay rule
      delay_seconds = extract_delay(connection)

      if delay_seconds > 0
        DeliverWebhookJob.set(wait: delay_seconds.seconds).perform_later(delivery.id)
      else
        DeliverWebhookJob.perform_later(delivery.id)
      end
    end
  end

  private

  def passes_filters?(event, connection)
    rules = connection.rules || []

    filter_rules = rules.select { |r| r["type"] == "filter" }
    return true if filter_rules.empty?

    filter_rules.all? do |rule|
      config = rule["config"] || {}

      # Event type filter
      if config["event_types"].present?
        event_types = Array(config["event_types"])
        return false unless event_types.include?(event.event_type)
      end

      true
    end
  end

  def extract_delay(connection)
    rules = connection.rules || []
    delay_rule = rules.find { |r| r["type"] == "delay" }
    return 0 unless delay_rule

    delay_rule.dig("config", "seconds").to_i
  end
end
