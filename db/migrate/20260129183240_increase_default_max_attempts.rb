class IncreaseDefaultMaxAttempts < ActiveRecord::Migration[8.1]
  def change
    change_column_default :deliveries, :max_attempts, from: 5, to: 18
  end
end
