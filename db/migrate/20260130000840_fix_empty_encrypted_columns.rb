class FixEmptyEncryptedColumns < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE sources SET verification_secret = NULL WHERE verification_secret = ''"
    execute "UPDATE destinations SET auth_value = NULL WHERE auth_value = ''"
  end

  def down
    # No-op - NULL is valid for these columns
  end
end
