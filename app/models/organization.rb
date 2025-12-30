class Organization < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :invitations, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :destinations, dependent: :destroy

  validates :name, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  def owner
    memberships.find_by(role: :owner)&.user
  end

  def owners
    users.joins(:memberships).where(memberships: { role: :owner })
  end

  def admins
    users.joins(:memberships).where(memberships: { role: [:admin, :owner] })
  end
end
