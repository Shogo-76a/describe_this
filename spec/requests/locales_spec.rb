require 'rails_helper'

RSpec.describe "Locales", type: :request do
  describe "GET /update" do
    it "returns http success" do
      get "/locales/update"

      # localesコントローラのupdateアクションがredirect_backのため、statusを:redirectに設定。
      expect(response).to have_http_status(:redirect) 
    end
  end
end
