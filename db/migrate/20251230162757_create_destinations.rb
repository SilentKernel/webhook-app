class CreateDestinations < ActiveRecord::Migration[8.0]
  def change
    create_table :destinations do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.string :http_method, default: "POST"
      t.jsonb :headers, default: {}
      t.integer :auth_type, default: 0, null: false
      t.string :auth_value
      t.integer :status, default: 0, null: false
      t.integer :timeout_seconds, default: 30
      t.integer :max_delivery_rate

      t.timestamps
    end

    add_index :destinations, :status
  end
end
