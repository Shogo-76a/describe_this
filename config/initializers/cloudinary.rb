# 初期化ファイルに設定を記述することで、Cloudinary::Search などの SDK（Gem）独自の機能にも Cloudinary設定 を自動的に読み込みこませる。
Cloudinary.config do |config|
  config.cloud_name = Rails.application.credentials.dig(:cloudinary, :cloud_name)
  config.api_key    = Rails.application.credentials.dig(:cloudinary, :api_key)
  config.api_secret = Rails.application.credentials.dig(:cloudinary, :api_secret)
  config.secure     = true # URLを常に https にする設定
end