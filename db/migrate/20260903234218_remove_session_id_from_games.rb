class RemoveSessionIdFromGames < ActiveRecord::Migration[8.1]
  def change
    remove_column :games, :session_id, :string
  end
end
