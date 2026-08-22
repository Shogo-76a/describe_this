class RenameArrayDescriptionToArrayContext < ActiveRecord::Migration[8.1]
  def change
    rename_column :games, :array_description, :array_context
  end
end
