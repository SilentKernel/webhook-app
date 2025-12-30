class Connection < ApplicationRecord
  belongs_to :source
  belongs_to :destination
  has_one :organization, through: :source
  has_many :deliveries, dependent: :destroy

  enum :status, { active: 0, paused: 1, disabled: 2 }

  validates :source_id, uniqueness: { scope: :destination_id, message: "already has a connection to this destination" }
  validate :source_and_destination_same_organization

  scope :active, -> { where(status: :active) }
  scope :ordered, -> { order(priority: :asc) }

  private

  def source_and_destination_same_organization
    return if source.blank? || destination.blank?

    if source.organization_id != destination.organization_id
      errors.add(:base, "source and destination must belong to the same organization")
    end
  end
end
