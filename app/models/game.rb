# == Schema Information
#
# Table name: games
#
#  id                :bigint           not null, primary key
#  array_description :string           default([]), is an Array
#  description       :text
#  feedback          :jsonb
#  image_seq         :integer          default(0), not null
#  message_seq       :integer          default(0), not null
#  theme_image_url   :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  session_id        :string
#
class Game < ApplicationRecord
    has_one_attached :generated_image
    validates :description, presence: true, on: :update
    # description カラムに文字が入っていれば、ユーザーからのメッセージと判定する
    def from_user?
        self.description.present?
    end
end
