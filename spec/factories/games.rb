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
FactoryBot.define do
  factory :game do
    user_id { nil }
    description  { 'A girl wears a pink jaket holds a tiney dog and is smiling at this way.' } # 意図的にスペルミスを含む（jaket:jacket, tiney:tiny)
    feedback { nil }
    theme_image_url { "https://res.cloudinary.com/dy8jwyu6v/image/upload/c_fill,f_auto,h_100,q_auto,w_150//main-sample.png" }

    # 外部APIとのVCR通信テスト用のトレイト
    trait :with_generated_image do
      # メモリ上のローカルダミーファイルを添付
      generated_image do
        Rack::Test::UploadedFile.new(
          Rails.root.join('spec/fixtures/files/dummy_generated_image_001.jpg'),
          'image/jpeg'
        )
      end
    end

    trait :with_feedback do
      feedback {
        {"overall" => 75,
         "proposals" => [
          {"bonus_phrase" => {"phrase" => "stretches across", "example" => "The river stretches across the valley, creating a beautiful view.", "meaning" => "広がる、または延びるという意味。", "example_translation" => "その川は谷を広がって流れ、美しい景色を作り出しています。"},
          "original_text" => "Mountain range goes horizontaly.", "rewritten_text" => "The mountain range stretches horizontally across the landscape."}, 
          {"bonus_phrase" => {"phrase" => "shrouded in clouds", "example" => "The castle was shrouded in clouds, giving it a mysterious appearance.", "meaning" => "雲に覆われているという意味。", "example_translation" => "その城は雲に覆われていて、神秘的な外観を与えています。"},
          "original_text" => "I see it from bird's-eye level and the top part of the mountain is covered with cloud, I can't see through anything.", "rewritten_text" => "From a bird's-eye view, I see the mountain's peak shrouded in clouds, completely obscuring my view."}, 
          {"bonus_phrase" => {"phrase" => "get closer", "example" => "As we get closer to the city, the buildings become more visible.", "meaning" => "近づくという意味。", "example_translation" => "私たちがその街に近づくにつれて、建物がより見えるようになります。"}, 
          "original_text" => "Getting closer, nice! I want it to get more high mountains shaped more spiky.", "rewritten_text" => "As I get closer, I hope to see taller mountains with sharper, spiky peaks."}], 
          "image_analysis" => "全体的に、ユーザーの説明は画像の主要な要素を伝えていますが、いくつかの詳細が不足しています。\n\n成功点としては、雲に覆われた山の上部や、鳥瞰図からの視点がしっかりと表現されています。しかし、山の形状や色合いについての具体的な描写が欠けており、特に「スパイキーな山」という要望が十分に伝わっていません。\n\n次回は、山の具体的な形や色、雲の動きなど、より詳細な描写を加えると良いでしょう。特に、山の高さや鋭さを強調することで、よりイメージが伝わりやすくなります。", 
          "title_for_history" => "Cloud-Capped Peaks"}
      }
    end
  end
end
