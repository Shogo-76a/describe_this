module Guest
  class BaseController < ApplicationController
    # ゲスト用コントローラの基底クラス
    allow_unauthenticated_access
    
    before_action :redirect_if_authenticated
    
    private
    
    def redirect_if_authenticated
      redirect_to games_path if authenticated?
      Rails.logger.debug "これは authenticated?: #{authenticated?}"
    end
  end
end