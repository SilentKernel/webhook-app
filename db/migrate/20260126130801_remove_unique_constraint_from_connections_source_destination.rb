class RemoveUniqueConstraintFromConnectionsSourceDestination < ActiveRecord::Migration[8.1]
  def change
    # Remove the unique constraint but keep a non-unique index for query performance
    remove_index :connections, [:source_id, :destination_id]
    add_index :connections, [:source_id, :destination_id]
  end
end
