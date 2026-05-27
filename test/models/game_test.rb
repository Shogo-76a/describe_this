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
require "test_helper"

class GameTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
