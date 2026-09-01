class LocalesController < ApplicationController
  allow_unauthenticated_access
  # Cookieに言語変更を書き込む
  def update
    cookies[:locale] = params[:locale]
    redirect_back fallback_location: root_path
  end
end
