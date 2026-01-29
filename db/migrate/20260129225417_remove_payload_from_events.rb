class RemovePayloadFromEvents < ActiveRecord::Migration[8.1]
  def up
    remove_column :events, :payload
  end

  def down
    add_column :events, :payload, :jsonb, default: {}
  end
end
