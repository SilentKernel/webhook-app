class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  enum :role, { member: 0, admin: 1, owner: 2 }, default: :member

  validates :user_id, uniqueness: { scope: :organization_id, message: "is already a member of this organization" }
  validate :only_one_owner_per_organization, if: :owner?

  private

  def only_one_owner_per_organization
    return unless organization

    existing_owner = organization.memberships.where(role: :owner).where.not(id: id).exists?
    if existing_owner
      errors.add(:role, "can only have one owner per organization")
    end
  end
end
