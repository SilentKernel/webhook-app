# frozen_string_literal: true

class AddTimezoneToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :timezone, :string, default: "UTC", null: false
  end
end
