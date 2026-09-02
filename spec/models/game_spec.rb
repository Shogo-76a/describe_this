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
require 'rails_helper'

RSpec.describe Game, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
