module Guest
  class BaseController < ApplicationController
    # ゲスト用コントローラの基底クラス
    allow_unauthenticated_access

    before_action :redirect_if_authenticated

    private

    def redirect_if_authenticated
      redirect_to root_path if authenticated?
    end
  end
end
