require 'rails_helper'

RSpec.describe "Locales", type: :request do
  describe "GET /update" do
    it "returns http success" do
      get "/locales/update"
      expect(response).to have_http_status(:success)
    end
  end

end
