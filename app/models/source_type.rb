class SourceType < ApplicationRecord
  belongs_to :verification_type
  has_many :sources, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  # For backward compatibility and convenience
  def verification_type_slug
    verification_type&.slug
  end
end
