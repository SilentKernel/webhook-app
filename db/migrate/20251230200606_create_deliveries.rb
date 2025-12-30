# frozen_string_literal: true

class CreateDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :deliveries do |t|
      t.references :event, null: false, foreign_key: true
      t.references :connection, null: false, foreign_key: true
      t.references :destination, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.integer :attempt_count, default: 0, null: false
      t.integer :max_attempts, default: 5, null: false
      t.datetime :next_attempt_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :deliveries, :status
    add_index :deliveries, :next_attempt_at
    add_index :deliveries, [ :status, :next_attempt_at ]
  end
end
