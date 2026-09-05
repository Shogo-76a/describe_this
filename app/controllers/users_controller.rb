class UsersController < ApplicationController
  def top
    if authenticated?
      @user = current_user
    else
      redirect_to root_path
    end
  end

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
