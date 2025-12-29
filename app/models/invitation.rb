class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by, class_name: "User", optional: true

  enum :role, { member: 0, admin: 1 }, default: :member

  has_secure_token :token

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :organization_id, message: "has already been invited to this organization" }
  validates :expires_at, presence: true

  before_validation :set_expires_at, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  def pending?
    accepted_at.nil? && expires_at > Time.current
  end

  def expired?
    expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user)
    return false if expired? || accepted?

    transaction do
      update!(accepted_at: Time.current)
      organization.memberships.create!(user: user, role: role)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def set_expires_at
    self.expires_at ||= 7.days.from_now
  end
end
