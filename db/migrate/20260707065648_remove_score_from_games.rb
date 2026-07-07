class RemoveScoreFromGames < ActiveRecord::Migration[8.1]
  def change
    remove_column :games, :score, :jsonb
  end
end
