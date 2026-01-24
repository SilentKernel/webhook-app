class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id, dependent: :nullify
  has_many :destination_notification_subscriptions, dependent: :destroy
  has_many :subscribed_destinations, through: :destination_notification_subscriptions, source: :destination

  validates :first_name, presence: true
  validates :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def can_receive_failure_email?
    confirmed? && (last_failure_email_sent_at.nil? || last_failure_email_sent_at < 10.minutes.ago)
  end
end
