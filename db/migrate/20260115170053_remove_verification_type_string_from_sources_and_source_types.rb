class RemoveVerificationTypeStringFromSourcesAndSourceTypes < ActiveRecord::Migration[8.1]
  def up
    remove_column :sources, :verification_type
    remove_column :source_types, :verification_type
  end

  def down
    add_column :sources, :verification_type, :string, null: false, default: "none"
    add_column :source_types, :verification_type, :string, null: false, default: "none"

    # Restore data from verification_type_id
    execute <<-SQL.squish
      UPDATE sources
      SET verification_type = verification_types.slug
      FROM verification_types
      WHERE sources.verification_type_id = verification_types.id
    SQL

    execute <<-SQL.squish
      UPDATE source_types
      SET verification_type = verification_types.slug
      FROM verification_types
      WHERE source_types.verification_type_id = verification_types.id
    SQL
  end
end
