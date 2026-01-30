class Connection < ApplicationRecord
  belongs_to :source
  belongs_to :destination
  has_one :organization, through: :source
  has_many :deliveries, dependent: :destroy

  enum :status, { active: 0, paused: 1, disabled: 2 }

  validate :source_and_destination_same_organization
  validate :unique_source_destination_rules_combination

  scope :active, -> { where(status: :active) }
  scope :ordered, -> { order(priority: :asc) }

  # Check if an event passes all filter rules for this connection
  def passes_filters?(event)
    filter_rules = (rules || []).select { |r| r["type"] == "filter" }
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

  # Get the delay in seconds from delay rules, or 0 if no delay
  def delay_seconds
    delay_rule = (rules || []).find { |r| r["type"] == "delay" }
    return 0 unless delay_rule

    delay_rule.dig("config", "seconds").to_i
  end

  private

  def source_and_destination_same_organization
    return if source.blank? || destination.blank?

    if source.organization_id != destination.organization_id
      errors.add(:base, "source and destination must belong to the same organization")
    end
  end

  def unique_source_destination_rules_combination
    return if source_id.blank? || destination_id.blank?

    existing_connections = Connection.where(source_id: source_id, destination_id: destination_id)
    existing_connections = existing_connections.where.not(id: id) if persisted?

    if existing_connections.any? { |conn| conn.rules == rules }
      errors.add(:base, "a connection with the same source, destination, and rules already exists")
    end
  end
end
