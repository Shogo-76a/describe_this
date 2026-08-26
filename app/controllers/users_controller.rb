class UsersController < ApplicationController
  include Authentication
  def show
    @user = current_user
  end

  def privacy_policy; end
  def terms; end

private

  def current_user
    Current.session&.user
  end
  helper_method :current_user

end
