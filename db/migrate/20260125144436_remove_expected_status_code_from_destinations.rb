class RemoveExpectedStatusCodeFromDestinations < ActiveRecord::Migration[8.1]
  def change
    remove_column :destinations, :expected_status_code, :integer
  end
end
