require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Minitest 用ファイルの自動生成を無効化し、RSpec を優先する
    config.generators do |g|
      g.test_framework :rspec
    end

    # エラー時に元のデザインを崩さないための設定
    config.action_view.field_error_proc = Proc.new do |html_tag, instance|
      # html_tag は Rails が生成した <input ...> などの文字列
      # Nokogiri を使って HTML を安全に解析
      doc = Nokogiri::HTML::DocumentFragment.parse(html_tag)
      element = doc.at('input, textarea, select')

      if element
        # 既存の class に 'is-invalid'（または任意のクラス名）を追加
        existing_class = element['class']
        element['class'] = [existing_class, 'is-invalid'].compact.join(' ')
        doc.to_html.html_safe
      else
        html_tag
      end
    end

  end
end
