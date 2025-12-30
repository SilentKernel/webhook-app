class Source < ApplicationRecord
  belongs_to :organization
  belongs_to :source_type, optional: true
  has_many :connections, dependent: :destroy
  has_many :events, dependent: :destroy

  enum :status, { active: 0, paused: 1 }

  encrypts :verification_secret

  validates :name, presence: true
  validates :ingest_token, presence: true, uniqueness: true
  validates :verification_type, presence: true,
    inclusion: { in: %w[stripe shopify github hmac none] }

  before_validation :generate_ingest_token, on: :create
  before_validation :set_verification_from_source_type, on: :create

  def ingest_url
    "/ingest/#{ingest_token}"
  end

  private

  def generate_ingest_token
    self.ingest_token = SecureRandom.urlsafe_base64(24) if ingest_token.blank?
  end

  def set_verification_from_source_type
    if source_type.present? && verification_type.blank?
      self.verification_type = source_type.verification_type
    end
  end
end
