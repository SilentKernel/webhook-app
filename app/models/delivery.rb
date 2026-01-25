# frozen_string_literal: true

class Delivery < ApplicationRecord
  MAX_BACKOFF_MINUTES = 1440 # 24 hours

  belongs_to :event
  belongs_to :connection
  belongs_to :destination
  has_many :delivery_attempts, dependent: :destroy
  has_one :source, through: :event
  has_one :organization, through: :event

  enum :status, { pending: 0, queued: 1, delivering: 2, success: 3, failed: 4 }

  validates :status, presence: true
  validates :attempt_count, numericality: { greater_than_or_equal_to: 0 }
  validates :max_attempts, numericality: { greater_than: 0 }

  scope :pending_retry, -> {
    where(status: [ :pending, :failed ])
      .where("next_attempt_at <= ?", Time.current)
      .where("attempt_count < max_attempts")
  }
  scope :successful, -> { where(status: :success) }
  scope :failed, -> { where(status: :failed).where("attempt_count >= max_attempts") }
  scope :in_progress, -> { where(status: [ :queued, :delivering ]) }

  def can_retry?
    attempt_count < max_attempts
  end

  def retryable?
    failed?
  end

  def mark_success!
    increment!(:attempt_count)
    update!(status: :success, completed_at: Time.current)
  end

  def mark_failed!
    increment!(:attempt_count)

    if can_retry?
      update!(status: :failed, next_attempt_at: calculate_next_attempt_at)
    else
      update!(status: :failed, completed_at: Time.current, next_attempt_at: nil)
    end
  end

  def calculate_next_attempt_at
    backoff_minutes = [ 2**attempt_count, MAX_BACKOFF_MINUTES ].min
    Time.current + backoff_minutes.minutes
  end
end
