# frozen_string_literal: true

class VerificationType < ApplicationRecord
  has_many :sources, dependent: :restrict_with_error
  has_many :source_types, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :active, -> { where(active: true).order(:position) }

  # Find by slug for seed operations
  def self.find_by_slug!(slug)
    find_by!(slug: slug)
  end
end
