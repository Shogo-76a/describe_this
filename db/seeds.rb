# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

admin_credentials = Rails.application.credentials.admin
if admin_credentials.present?
  User.find_or_create_by!(name: admin_credentials[:name], email_address: admin_credentials[:email_address]) do |user|
    user.password = admin_credentials[:password]
    user.admin = true # 最初から管理者に設定
  end
end
