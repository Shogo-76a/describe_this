require 'rails_helper'

RSpec.describe "Documents", type: :request do
  describe "正常にレスポンスを返すこと" do
    it "プライバシーポリシー" do
      get documents_privacy_policy_path
      expect(response).to have_http_status(:success)
    end

    it "利用規約" do
      get documents_terms_path
      expect(response).to have_http_status(:success)
    end
  end
end
