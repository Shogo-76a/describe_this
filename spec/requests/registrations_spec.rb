require 'rails_helper'

RSpec.describe "通常ユーザー登録", type: :request do
  # FactoryBot からパラメーター用のハッシュを生成
  let(:valid_params) do
    {
      name: "新規テスト太郎",
      email_address: "normal_signup@example.com",
      password: "password123"
    }
  end

  describe "POST registrations/create" do
    context "正しいパラメーターが送られた場合" do
      it "ユーザーが新規作成されること" do
        expect {
          post registrations_path, params: { user: valid_params } # もしルーティングがgetのままなら get "/registrations/create"
        }.to change(User, :count).by(1)
      end

      it "登録成功後のページにリダイレクトされること" do
        post registrations_path, params: { user: valid_params }
        expect(response).to redirect_to(root_path) # 実際の遷移先に合わせて変更してください
      end
    end

    context "不適切なパラメーター（名前が空など）の場合" do
      it "ユーザーが作成されないこと" do
        expect {
          post registrations_path, params: { user: { name: "", email_address: "" } }
        }.not_to change(User, :count)
      end
    end
  end
end
