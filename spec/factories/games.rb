FactoryBot.define do
  factory :game do
    description  { 'テストデータテストテスト' }
    feedback { nil }
    score { nil }
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