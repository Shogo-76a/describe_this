# == Schema Information
#
# Table name: games
#
#  id              :bigint           not null, primary key
#  array_context   :text             default([]), is an Array
#  description     :text
#  feedback        :jsonb
#  image_seq       :integer          default(0), not null
#  locale_in_game  :string           default("en"), not null
#  message_seq     :integer          default(0), not null
#  mode            :integer          default(0), not null
#  theme_image_url :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :bigint
#
# Indexes
#
#  index_games_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Game < ApplicationRecord
    has_one_attached :generated_image
    belongs_to :user, optional: true # ゲストユーザーの場合は user_id つかないため、nullでも作成できるよう optional に設定。

    validates :description, presence: true, specific_language: true, on: :update # specific_languageは自作バリデータ

    enum :mode, { beginner: 0, elementary: 1, standard: 2 }

    # description カラムに文字が入っていれば、ユーザーからのメッセージと判定する
    def from_user?
        self.description.present?
    end
end
