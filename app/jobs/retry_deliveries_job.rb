# frozen_string_literal: true

class RetryDeliveriesJob < ApplicationJob
  queue_as :default

  # This job acts as a safety net for retries.
  # Main retries are scheduled directly in DeliverWebhookJob.
  # Run this periodically (every minute via cron/whenever/Sidekiq-Cron)
  # to catch any deliveries that may have been missed.
  def perform
    # Find deliveries that are ready for retry
    deliveries = Delivery.where(status: [ :pending, :failed ])
                         .where("next_attempt_at <= ?", Time.current)
                         .where("attempt_count < max_attempts")
                         .limit(100)

    deliveries.each do |delivery|
      DeliverWebhookJob.perform_later(delivery.id)
    end
  end
end
