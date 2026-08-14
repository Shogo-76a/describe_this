class DocumentsController < ApplicationController
  allow_unauthenticated_access only: %i[ privacy_policy terms ]
  before_action :set_user_if_authenticated, only: %i[privacy_policy terms]

  def privacy_policy; end
  def terms; end

private
  def set_user_if_authenticated
    @user = Current.user if authenticated?
  end
end
