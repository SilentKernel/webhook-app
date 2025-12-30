# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :source, null: false, foreign_key: true
      t.string :uid, null: false
      t.string :event_type
      t.jsonb :payload, default: {}
      t.jsonb :headers, default: {}
      t.jsonb :query_params, default: {}
      t.string :source_ip
      t.string :content_type
      t.datetime :received_at, null: false

      t.timestamps
    end

    add_index :events, :uid, unique: true
    add_index :events, :event_type
    add_index :events, :received_at
    add_index :events, [ :source_id, :received_at ]
  end
end
