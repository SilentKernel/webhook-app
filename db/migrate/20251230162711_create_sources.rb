class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :source_type, foreign_key: true
      t.string :name, null: false
      t.string :ingest_token, null: false
      t.string :verification_type, null: false
      t.string :verification_secret
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :sources, :ingest_token, unique: true
    add_index :sources, :status
  end
end
