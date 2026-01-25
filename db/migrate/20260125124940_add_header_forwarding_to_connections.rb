class AddHeaderForwardingToConnections < ActiveRecord::Migration[8.1]
  def change
    add_column :connections, :forward_all_headers, :boolean, default: false, null: false
    add_column :connections, :forward_headers, :text, array: true, default: []
  end
end
