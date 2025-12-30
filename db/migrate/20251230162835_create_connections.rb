class CreateConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :connections do |t|
      t.references :source, null: false, foreign_key: true
      t.references :destination, null: false, foreign_key: true
      t.string :name
      t.jsonb :rules, default: []
      t.integer :status, default: 0, null: false
      t.integer :priority, default: 0

      t.timestamps
    end

    add_index :connections, :status
    add_index :connections, [ :source_id, :destination_id ], unique: true
  end
end
