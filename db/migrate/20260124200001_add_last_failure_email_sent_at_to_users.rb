# frozen_string_literal: true

class AddLastFailureEmailSentAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_failure_email_sent_at, :datetime
    add_index :users, :last_failure_email_sent_at
  end
end
