class AddExpectedStatusCodeToDestinations < ActiveRecord::Migration[8.1]
  def change
    add_column :destinations, :expected_status_code, :integer
  end
end
