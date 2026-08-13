class RegistrationsController < ApplicationController

  def new
    @new_user = User.new
  end

  def create
    @new_user = User.new(user_params)
    if @new_user.save
      # 登録成功時にセッションを開始してログイン状態にする (Rails 8標準機能)
      session_record = @new_user.sessions.create!
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

