class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :session_id
      t.text :description
      t.string :theme_image_url
      t.integer :score
      t.jsonb :feedback

      t.timestamps
    end
  end
end
