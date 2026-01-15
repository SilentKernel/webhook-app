class CreateVerificationTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :verification_types do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :verification_types, :slug, unique: true
    add_index :verification_types, :active
    add_index :verification_types, :position
  end
end
