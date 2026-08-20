class AddColumnsToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :message_seq, :integer, default: 0, null: false
    add_column :games, :image_seq, :integer, default: 0, null: false
  end
end
