class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  if Rails.env.production?
    allow_browser versions: :modern
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # メニュー言語をCookieから読み込んでI18nに反映する
  around_action :switch_locale

  # ゲームで使う言語をCookieから読み込んでCurrentモデルに保存する
  before_action :set_locale_in_game

  # ゲームモードををCookieから読み込んでCurrentモデルに保存 → 自作バリデータで値を使う
  before_action :set_mode_context


  private

  # メニュー言語
  def switch_locale(&action)
    I18n.default_locale = "ja"
    # .presence を使うことで、params が空なら cookies を見に行くようになる
    locale = params[:locale].presence || cookies[:locale].presence || I18n.default_locale
    cookies[:locale] = locale if params[:locale].present?
    I18n.with_locale(locale, &action)
  end


  # ゲーム内言語
  def set_locale_in_game
    # paramsまたはcookieからゲームで使う言語設定を取得（なければ "ja"）
    locale_in_game = params[:job_param].to_s.presence || cookies[:job_param].to_s.presence || "ja"
    cookies[:job_param] = locale_in_game if params[:job_param].present?
    Current.locale_in_game = locale_in_game

    Rails.logger.info "=== DEBUG set_locale_in_game ==="
    Rails.logger.info "locale_in_game: #{locale_in_game}"
    Rails.logger.info "====================="
  end


  # ゲームモード（他言語の使用OKか否か）
  def set_mode_context
    # paramsまたはcookieからゲームモードを取得（なければ 0 翻訳サポートあり）

    # 先に .presence で存在確認してから .to_i を適用する
    raw_mode = params[:mode].presence || cookies[:mode].presence || 0

    # params も cookies も両方空ならデフォルトの 0 にする
    mode = raw_mode ? raw_mode.to_i : 0

    # params が存在するときだけ Cookie を更新
    cookies[:mode] = mode if params[:mode].present?



    # バリデータspecific_language_validatorに渡すため、Currentモデルのアトリビュートに値を保存。
    Current.mode = mode
    # 許可する言語を 限定するかしないか を切り替える
    Current.allowed_languages = case mode
    when 0
                                  nil # nil の場合はバリデーションをスキップする目印にする
    when 2
                                  [ Current.locale_in_game ] # 'en' などが入る
    else
                                  nil # デフォルト
    end

    Rails.logger.info "=== DEBUG set_mode_context ==="
    Rails.logger.info "mode: #{mode}"
    Rails.logger.info "====================="
  end
end
