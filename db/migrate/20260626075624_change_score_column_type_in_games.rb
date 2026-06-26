class ChangeScoreColumnTypeInGames < ActiveRecord::Migration[8.1]
  def change
    change_column :games, :score, :jsonb, using: "to_jsonb(score)"
  end
end
