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
FactoryBot.define do
  factory :game do
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
  end
end
