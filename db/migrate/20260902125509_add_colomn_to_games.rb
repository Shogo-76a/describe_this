class AddColomnToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :locale_in_game, :string, default: "en", null: false
  end
end
