module Guest
  class BaseController < ApplicationController
    include Authentication
    # ゲスト用コントローラの基底クラス
    allow_unauthenticated_access

    before_action :redirect_if_authenticated

    private

    def redirect_if_authenticated
      redirect_to top_user_path(current_user.id) if authenticated?
    end

    def current_user
      Current.session&.user
    end
    helper_method :current_user

  end
end
