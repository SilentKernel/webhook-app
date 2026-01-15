class AddVerificationTypeIdToSourcesAndSourceTypes < ActiveRecord::Migration[8.1]
  def up
    # First, seed the verification types if they don't exist
    seed_verification_types

    # Add verification_type_id columns (nullable initially for migration)
    add_reference :sources, :verification_type, null: true, foreign_key: true, index: true
    add_reference :source_types, :verification_type, null: true, foreign_key: true, index: true

    # Migrate existing string data to foreign keys
    migrate_sources_data
    migrate_source_types_data

    # Now make the columns not null
    change_column_null :sources, :verification_type_id, false
    change_column_null :source_types, :verification_type_id, false
  end

  def down
    remove_reference :sources, :verification_type
    remove_reference :source_types, :verification_type

    # Note: VerificationType records are left in place - they can be removed manually if needed
  end

  private

  def seed_verification_types
    verification_types = [
      { name: "None / Custom", slug: "none", description: "No signature verification", position: 0 },
      { name: "Stripe", slug: "stripe", description: "Stripe webhook signature verification", position: 1 },
      { name: "Shopify", slug: "shopify", description: "Shopify HMAC verification", position: 2 },
      { name: "GitHub", slug: "github", description: "GitHub webhook signature", position: 3 },
      { name: "Generic HMAC", slug: "hmac", description: "Generic HMAC-SHA256 verification", position: 4 }
    ]

    verification_types.each do |attrs|
      execute <<-SQL.squish
        INSERT INTO verification_types (name, slug, description, active, position, created_at, updated_at)
        SELECT '#{attrs[:name]}', '#{attrs[:slug]}', '#{attrs[:description]}', true, #{attrs[:position]}, NOW(), NOW()
        WHERE NOT EXISTS (SELECT 1 FROM verification_types WHERE slug = '#{attrs[:slug]}')
      SQL
    end
  end

  def migrate_sources_data
    execute <<-SQL.squish
      UPDATE sources
      SET verification_type_id = verification_types.id
      FROM verification_types
      WHERE sources.verification_type = verification_types.slug
    SQL
  end

  def migrate_source_types_data
    execute <<-SQL.squish
      UPDATE source_types
      SET verification_type_id = verification_types.id
      FROM verification_types
      WHERE source_types.verification_type = verification_types.slug
    SQL
  end
end
