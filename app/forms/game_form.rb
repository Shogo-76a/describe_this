# == Schema Information
#
# Table name: games
#
#  id              :bigint           not null, primary key
#  description     :text
#  feedback        :jsonb
#  score           :integer
#  theme_image_url :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  session_id      :string
#

class GameForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    # 値を持たせる（初期化する）ための属性を定義する
    attribute :description, :string
    attribute :feedback, :string, default: -> { [] }

    # description カラムに文字が入っていれば、ユーザーからのメッセージと判定する
    def from_user?
        self.description.present?
    end
end
