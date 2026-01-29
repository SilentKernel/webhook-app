class ChangeRawBodyFromBinaryToText < ActiveRecord::Migration[8.1]
  def up
    # Change raw_body from binary to text to support Active Record Encryption
    change_column :events, :raw_body, :text

    # Decode hex-encoded data (PostgreSQL converts binary to \x... format when cast to text)
    say_with_time "Decoding hex-encoded raw_body data" do
      execute <<-SQL
        UPDATE events
        SET raw_body = convert_from(decode(substring(raw_body from 3), 'hex'), 'UTF8')
        WHERE raw_body IS NOT NULL AND raw_body LIKE '\\\\x%'
      SQL
    end
  end

  def down
    change_column :events, :raw_body, :binary
  end
end
