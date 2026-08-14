class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # 登録成功時にセッションを開始してログイン状態にする (Rails 8標準機能)
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_id] = session_record.id
      
      redirect_to root_path, notice: "会員登録が完了しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :name, :email_address, :password, :password_confirmation ])
  end
end

