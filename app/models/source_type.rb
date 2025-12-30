class SourceType < ApplicationRecord
  has_many :sources, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :verification_type, presence: true

  scope :active, -> { where(active: true) }
end
