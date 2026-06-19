class AddChannelHashToSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :solid_cable_messages, :channel_hash, :bigint
  end
end
