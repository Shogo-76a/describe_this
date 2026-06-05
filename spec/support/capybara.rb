require 'capybara/rspec'
RSpec.configure do |config|
  config.before(:each, type: :system) do
    if ENV['CI']
      # --- GitHub Actions（CI）用の設定 ---
      # 外部コンテナを使わず、Runner環境のChromeを直接ヘッドレスで起動
      driven_by :selenium, using: :headless_chrome do |options|
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-gpu")
        options.add_argument("--disable-dev-shm-usage") # CI環境でのメモリ不足防止
        options.add_argument("--window-size=1400,1400")
      end

      Capybara.server_host = "127.0.0.1"
      Capybara.server_port = 3001
      Capybara.app_host = "http://127.0.0.1:#{Capybara.server_port}"

      Capybara.default_max_wait_time = 10
    else

      # --- ローカル環境（Docker Compose等）用の設定 ---
      Capybara.register_driver :remote_chrome do |app|
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-gpu")
        options.add_argument("--window-size=1400,1400")

        Capybara::Selenium::Driver.new(
          app,
          browser: :remote,
          url: "http://chrome:4444/wd/hub",
          capabilities: options
        )
      end

      driven_by :remote_chrome

      Capybara.server_host = "web"
      Capybara.server_port = 3001
      Capybara.app_host = "http://web:#{Capybara.server_port}"
    end
  end
end
