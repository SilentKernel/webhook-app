class EncryptExistingData < ActiveRecord::Migration[8.1]
  def up
    # Temporarily disable encryption to read plaintext data
    say_with_time "Encrypting events.raw_body" do
      execute_in_batches("events", "raw_body")
    end

    say_with_time "Encrypting delivery_attempts.request_body" do
      execute_in_batches("delivery_attempts", "request_body")
    end

    say_with_time "Encrypting delivery_attempts.response_body" do
      execute_in_batches("delivery_attempts", "response_body")
    end

    say_with_time "Encrypting sources.verification_secret" do
      execute_in_batches("sources", "verification_secret")
    end

    say_with_time "Encrypting destinations.auth_value" do
      execute_in_batches("destinations", "auth_value")
    end
  end

  def down
    # Data remains readable - decryption happens automatically
  end

  private

  def execute_in_batches(table, column)
    # Read plaintext data directly from DB, encrypt and write back
    records = execute("SELECT id, #{column} FROM #{table} WHERE #{column} IS NOT NULL")
    records.each do |row|
      plaintext = row[column]
      next if plaintext.blank?
      next if already_encrypted?(plaintext)

      encrypted = encrypt_value(plaintext)
      execute(sanitize_sql_array([
        "UPDATE #{table} SET #{column} = ? WHERE id = ?",
        encrypted, row["id"]
      ]))
    end
  end

  def already_encrypted?(value)
    # Encrypted values start with a JSON-like structure
    value.to_s.start_with?('{"p":')
  end

  def encrypt_value(plaintext)
    encryptor = ActiveRecord::Encryption::Encryptor.new
    encryptor.encrypt(plaintext)
  end

  def sanitize_sql_array(array)
    ActiveRecord::Base.sanitize_sql_array(array)
  end
end
