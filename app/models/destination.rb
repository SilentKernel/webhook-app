class Destination < ApplicationRecord
  belongs_to :organization
  has_many :connections, dependent: :destroy
  has_many :deliveries, dependent: :destroy
  has_many :destination_notification_subscriptions, dependent: :destroy
  has_many :notification_subscribers, through: :destination_notification_subscriptions, source: :user

  enum :status, { active: 0, paused: 1, disabled: 2 }, prefix: true
  enum :auth_type, { none: 0, bearer: 1, basic: 2, api_key: 3 }, prefix: true

  validates :name, presence: true
  validates :url, presence: true,
    format: { with: /\Ahttps?:\/\/.+\z/i, message: "must be a valid HTTP or HTTPS URL" }
  validates :http_method, inclusion: { in: %w[POST PUT PATCH GET DELETE] }
  validates :timeout_seconds, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_delivery_rate, numericality: { greater_than: 0 }, allow_nil: true
end
