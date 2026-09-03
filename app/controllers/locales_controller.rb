class LocalesController < ApplicationController
  allow_unauthenticated_access
  # Cookieに言語変更を書き込むと、switch_locale（親コントローラのメソッド）が発火→I18nに反映される。
  def update
    cookies[:locale] = params[:locale]
    redirect_back fallback_location: root_path
  end

  def update_locale_in_game
    cookies[:job_param] = params[:job_param]
    redirect_back fallback_location: root_path
  end
end
