# == Schema Information
#
# Table name: games
#
#  id              :bigint           not null, primary key
#  description     :text
#  feedback        :jsonb
#  score           :jsonb
#  theme_image_url :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  session_id      :string
#
require 'rails_helper'

RSpec.describe Game, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
