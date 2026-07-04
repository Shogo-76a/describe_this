class DropSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    drop_table :solid_cable_messages if table_exists?(:solid_cable_messages)
  end
end
