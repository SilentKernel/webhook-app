# frozen_string_literal: true

class CreateDestinationNotificationSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :destination_notification_subscriptions do |t|
      t.belongs_to :destination, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :destination_notification_subscriptions,
              [:destination_id, :user_id],
              unique: true,
              name: "index_dest_notif_subs_on_destination_and_user"
  end
end
