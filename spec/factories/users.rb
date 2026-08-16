# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email_address   :string           not null
#  name            :string
#  password_digest :string           not null
#  provider        :string
#  uid             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#  index_users_on_name           (name) UNIQUE
#
FactoryBot.define do
  factory :user do
    email_address { "user@example.com" }
    password { "password" }
  end
end
