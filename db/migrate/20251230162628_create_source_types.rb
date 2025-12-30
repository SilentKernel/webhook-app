class CreateSourceTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :source_types do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :verification_type, null: false
      t.jsonb :default_config, default: {}
      t.string :icon
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :source_types, :slug, unique: true
  end
end
