# frozen_string_literal: true

class DestinationNotificationSubscription < ApplicationRecord
  belongs_to :destination
  belongs_to :user

  validates :user_id, uniqueness: { scope: :destination_id, message: "is already subscribed to this destination" }
  validate :user_belongs_to_destination_organization

  private

  def user_belongs_to_destination_organization
    return unless destination && user

    unless user.organizations.include?(destination.organization)
      errors.add(:user, "must belong to the destination's organization")
    end
  end
end
