# frozen_string_literal: true

class AddRawBodyToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :raw_body, :binary
    add_column :events, :body_is_binary, :boolean, default: false, null: false
    add_column :events, :body_size, :integer
  end
end
