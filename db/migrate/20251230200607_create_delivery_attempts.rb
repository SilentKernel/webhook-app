# frozen_string_literal: true

class CreateDeliveryAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_attempts do |t|
      t.references :delivery, null: false, foreign_key: true
      t.integer :attempt_number, null: false
      t.integer :status, default: 0, null: false
      t.string :request_url, null: false
      t.string :request_method, null: false
      t.jsonb :request_headers, default: {}
      t.text :request_body
      t.integer :response_status
      t.jsonb :response_headers, default: {}
      t.text :response_body
      t.integer :duration_ms
      t.string :error_message
      t.string :error_code
      t.datetime :attempted_at, null: false

      t.timestamps
    end

    add_index :delivery_attempts, :status
    add_index :delivery_attempts, :attempted_at
  end
end
