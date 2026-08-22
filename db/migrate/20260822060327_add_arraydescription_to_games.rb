class AddArraydescriptionToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :array_description, :text, array: true, default: []
  end
end
