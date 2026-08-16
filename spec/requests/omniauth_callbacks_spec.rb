require 'rails_helper'

RSpec.describe "OmniauthCallbacks", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/omniauth_callbacks/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /failure" do
    it "returns http success" do
      get "/omniauth_callbacks/failure"
      expect(response).to have_http_status(:success)
    end
  end

end
