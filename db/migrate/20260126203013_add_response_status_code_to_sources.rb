class AddResponseStatusCodeToSources < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :response_status_code, :integer
  end
end
