class Source < ApplicationRecord
  encrypts :verification_secret

  belongs_to :organization
  belongs_to :source_type, optional: true
  belongs_to :verification_type
  has_many :connections, dependent: :destroy
  has_many :events, dependent: :destroy

  enum :status, { active: 0, paused: 1 }

  validates :name, presence: true
  validates :ingest_token, presence: true, uniqueness: true
  validates :response_status_code, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 200,
    less_than: 300,
    allow_nil: true
  }

  before_validation :generate_ingest_token, on: :create
  before_validation :set_verification_from_source_type, on: :create

  def ingest_url
    "/ingest/#{ingest_token}"
  end

  # Used by SignatureVerifier to determine which verification method to use
  def verification_type_slug
    verification_type&.slug || "none"
  end

  # Returns the configured status code or 202 (Accepted) as default
  def success_status_code
    response_status_code || 202
  end

  private

  def generate_ingest_token
    self.ingest_token = SecureRandom.urlsafe_base64(24) if ingest_token.blank?
  end

  def set_verification_from_source_type
    if source_type.present? && verification_type_id.blank?
      self.verification_type = source_type.verification_type
    end
  end
end
