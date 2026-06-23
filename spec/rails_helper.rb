# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'selenium-webdriver'

# VCR の設定
require 'vcr'
require 'webmock/rspec'
VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true # vcrカセットがない時はhttp接続を許可する。
  config.cassette_library_dir = 'spec/vcr' # 記録ファイルの保存先
  config.hook_into :webmock                # WebMockと連携
  config.configure_rspec_metadata!         # vcr: trueで自動設定
  config.default_cassette_options = {
    record: :once, # record 設定
    match_requests_on: [ :method ] # メソッド（GET/POST）さえ合っていれば、過去のカセットを再生する
  }

  # vcrカセットを使う条件を緩和。メソッド（GET/POST）さえ合っていれば、過去のカセットを再生する。
  # urlなどが動的に変更される場合などは match_requests_on で条件から除外できる。
  config.ignore_hosts '127.0.0.1', 'localhost', 'chromedriver.storage.googleapis.com', 'chrome'

  # カセットに保存する前に、機密情報を "<GIT_CREDENTIALS>" のようなプレースホルダーに置き換える
  # Rails 8の credentials から該当の値を取得（階層に合わせて変更）
  config.filter_sensitive_data('<GIT_TOKEN>') do
    Rails.application.credentials.dig(:git, :access_token)
  end
  config.filter_sensitive_data('<GIT_PASSWORD>') do
    Rails.application.credentials.dig(:git, :password)
  end

  # OpenAI用のマスク設定
  config.filter_sensitive_data('<OPENAI_API_KEY>') do
    Rails.application.credentials.dig(:openai, :api_key)
  end

  # DeepInfra用のマスク設定
  config.filter_sensitive_data('<DEEPINFRA_API_KEY>') do
    Rails.application.credentials.dig(:deepinfra, :api_key)
  end

  # Cloudinary用のマスク設定
  config.filter_sensitive_data('<CLOUDINARY_API_KEY>') do
    Rails.application.credentials.dig(:cloudinary, :api_key)
  end
  config.filter_sensitive_data('<CLOUDINARY_API_SECRET>') do
    Rails.application.credentials.dig(:cloudinary, :api_secret)
  end
  config.filter_sensitive_data('<CLOUDINARY_CLOUD_NAME>') do
    Rails.application.credentials.dig(:cloudinary, :cloud_name)
  end
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/8-0/rspec-rails
  #
  # You can also infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  # config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
