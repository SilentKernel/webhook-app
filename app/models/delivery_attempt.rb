# frozen_string_literal: true

class DeliveryAttempt < ApplicationRecord
  belongs_to :delivery
  has_one :event, through: :delivery
  has_one :destination, through: :delivery

  enum :status, { pending: 0, success: 1, failed: 2 }

  validates :attempt_number, presence: true, numericality: { greater_than: 0 }
  validates :request_url, presence: true
  validates :request_method, presence: true
  validates :attempted_at, presence: true

  def success?
    return false if response_status.blank?

    response_status >= 200 && response_status < 300
  end

  def duration_seconds
    return nil unless duration_ms

    duration_ms / 1000.0
  end
end
