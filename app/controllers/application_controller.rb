class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  if Rails.env.production?
    allow_browser versions: :modern
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Cookie読み込んでI18nに反映する
  around_action :switch_locale

  private

  def switch_locale(&action)
    I18n.default_locale = "ja"
    locale = params[:locale] || cookies[:locale] || I18n.default_locale
    cookies[:locale] = locale if params[:locale].present?
    I18n.with_locale(locale, &action)
  end
end
