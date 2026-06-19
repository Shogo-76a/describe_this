class CreateSolidCableTables < ActiveRecord::Migration[8.0]
  def change
    # db/cable_schema.rb の中身をここに移植
    create_table :solid_cable_messages, force: :cascade do |t|
      t.binary :channel, null: false, limit: 1024
      t.binary :payload, null: false, limit: 536870912
      t.datetime :created_at, null: false

      t.index :channel, name: "index_solid_cable_messages_on_channel"
      t.index :created_at, name: "index_solid_cable_messages_on_created_at"
    end
  end
end
