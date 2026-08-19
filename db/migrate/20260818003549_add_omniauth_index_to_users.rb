class AddOmniauthIndexToUsers < ActiveRecord::Migration[8.1]
  def change
    # 二重登録バグ防止
    add_index :users, [ :provider, :uid ], unique: true
  end
end
