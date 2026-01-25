class AddDefaultForwardHeadersToSourceTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :source_types, :default_forward_headers, :text, array: true, default: []
  end
end
