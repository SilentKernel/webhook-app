# frozen_string_literal: true

class Event < ApplicationRecord
  encrypts :raw_body

  belongs_to :source
  has_many :deliveries, dependent: :destroy
  has_one :organization, through: :source

  enum :status, {
    received: 0,
    authentication_failed: 1,
    payload_too_large: 2
  }, default: :received

  validates :uid, presence: true, uniqueness: true
  validates :received_at, presence: true

  before_validation :generate_uid, on: :create

  scope :recent, -> { order(received_at: :desc) }
  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :since, ->(time) { where("received_at >= ?", time) }
  scope :until, ->(time) { where("received_at <= ?", time) }
  scope :by_status, ->(status) { where(status: status) }

  # Check if this event can be replayed (only successfully received events can be replayed)
  def replayable?
    received?
  end

  # Content-type detection helpers
  def json?
    content_type.to_s.include?("application/json")
  end

  def xml?
    content_type.to_s.include?("xml")
  end

  def form_urlencoded?
    content_type.to_s.include?("application/x-www-form-urlencoded")
  end

  def text?
    content_type.to_s.start_with?("text/")
  end

  def binary?
    body_is_binary
  end

  def displayable_body(max_length: 2000)
    return nil if raw_body.blank?
    return "[Binary content, #{body_size} bytes]" if binary?

    body_str = raw_body.force_encoding("UTF-8")
    return "[Invalid encoding, #{body_size} bytes]" unless body_str.valid_encoding?

    body_str.truncate(max_length)
  end

  # Parse raw_body as JSON (replaces payload column usage)
  def parsed_body
    return nil if raw_body.blank? || binary?

    JSON.parse(raw_body)
  rescue JSON::ParserError
    nil
  end

  private

  def generate_uid
    self.uid = SecureRandom.uuid if uid.blank?
  end
end
