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
class User < ApplicationRecord
  has_secure_password validations: false # 外部認証時はパスワード入力を必須にしない場合
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, uniqueness: true, length: { minimum: 1, maximum: 20 }

  def self.from_omniauth(auth)
    # 1. まずは「同じSNSアカウント（provider + uid）」で既に登録がないか探す
    user = find_by(provider: auth.provider, uid: auth.uid)

    # 2. SNSアカウントが見つからない場合、今度は「同じメールアドレス」のユーザーがいないか探す
    if user.nil? && auth.info.email.present?
      user = find_by(email_address: auth.info.email.downcase.strip)
      
      # メールアドレスで見つかった場合、その既存ユーザーにSNS情報を紐付ける
      if user
        user.update!(provider: auth.provider, uid: auth.uid)
      end
    end

    # 3. それでも見つからない（完全に新規のユーザー）なら、新しく作成する
    if user.nil?
      user = create do |u|
        u.provider = auth.provider
        u.uid = auth.uid
        u.email_address = auth.info.email
        u.password = SecureRandom.hex(16) # パスワードをランダム生成してバリデーションを回避
        u.name = auth.info.name なども追加
      end
    end

    user
  end
end
