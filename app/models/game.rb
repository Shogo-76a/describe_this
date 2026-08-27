# == Schema Information
#
# Table name: games
#
#  id              :bigint           not null, primary key
#  array_context   :string           default([]), is an Array
#  description     :text
#  feedback        :jsonb
#  image_seq       :integer          default(0), not null
#  message_seq     :integer          default(0), not null
#  theme_image_url :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  session_id      :string
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

    validates :description, presence: true, on: :update

    # description カラムに文字が入っていれば、ユーザーからのメッセージと判定する
    def from_user?
        self.description.present?
    end
end
