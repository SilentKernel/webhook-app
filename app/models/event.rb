# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :source
  has_many :deliveries, dependent: :destroy
  has_one :organization, through: :source

  validates :uid, presence: true, uniqueness: true
  validates :received_at, presence: true

  before_validation :generate_uid, on: :create

  scope :recent, -> { order(received_at: :desc) }
  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :since, ->(time) { where("received_at >= ?", time) }
  scope :until, ->(time) { where("received_at <= ?", time) }

  private

  def generate_uid
    self.uid = SecureRandom.uuid if uid.blank?
  end
end
