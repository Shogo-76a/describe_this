class AddColomnToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :locale_ingame, :string, default: "English", null: false
  end
end
