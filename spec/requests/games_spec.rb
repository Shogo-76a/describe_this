require 'rails_helper'

RSpec.describe "Games", type: :request do
  let(:game) { create(:game, :with_generated_image) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "GET /top" do
    it "正常にレスポンスを返すこと" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    context "params[:image_url] が存在する場合" do
      it "指定された image_url を持つ Game オブジェクトが割り当てられること" do
        get new_game_path, params: { image_url: "http://example.com/custom.png" }
        expect(response).to have_http_status(:success)
        # 画面上に該当URLが表示されるか等で検証できます
        expect(response.body).to include("http://example.com/custom.png")
      end
    end

    context "params[:image_url] が存在しない場合" do
      context "Cloudinary から画像が取得できた場合" do
        it "ランダムな画像が選択されて割り当てられること" do
          allow(CloudinaryFolderService).to receive(:fetch_images_from_folder).and_return([ "image1", "image2" ])
          get new_game_path
          expect(response).to have_http_status(:success)
        end
      end

      context "Cloudinary のフォルダが空の場合" do
        it "デフォルトのプレースホルダー画像 (placeholder_gray.png) が割り当てられること" do
          allow(CloudinaryFolderService).to receive(:fetch_images_from_folder).and_return([])
          get new_game_path
          expect(response.body).to include("placeholder_gray.png")
        end
      end

      context "Cloudinary でエラーが発生した場合 (例外処理)" do
        it "エラーを rescue し、フォールバック画像 (placeholder_white.png) が割り当てられること" do
          # 例外を発生させるモック
          allow(CloudinaryFolderService).to receive(:fetch_images_from_folder).and_raise(StandardError.new("Test API Error"))

          # ログが出力されることを期待
          expect(Rails.logger).to receive(:error).with("ThemeImagePicker Error: Test API Error")

          get new_game_path
          expect(response.body).to include("placeholder_white.png")
        end
      end
    end
  end

  describe "POST /games" do
    context "保存に成功する場合" do
      it "新しい Game を作成し、show アクションへリダイレクトすること" do
        expect {
          post games_path, params: { game: { theme_image_url: "test.png", description: "test desc" } }
        }.to change(Game, :count).by(1)
        expect(response).to redirect_to(Game.last)
      end
    end

    context "保存に失敗する場合" do
      it "Game を作成せず、new テンプレートをレンダリング (unprocessable_content) すること" do
        # 意図的に保存を失敗させるモック (バリデーションエラー等を想定)
        allow_any_instance_of(Game).to receive(:save).and_return(false)

        expect {
          post games_path, params: { game: { theme_image_url: "" } }
        }.not_to change(Game, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /games/:id" do
    it "正常にレスポンスを返すこと" do
      get game_path(game)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /games/:id" do
    context "更新に成功する場合" do
      it "Turbo Stream でレスポンスを返し、GenerateImageJob をエンキューすること" do
        expect {
          patch game_path(game), params: { game: { description: "updated text" } }, as: :turbo_stream
        }.to have_enqueued_job(GenerateImageJob).with(game, "English")

        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response).to have_http_status(:success)
      end
    end

    context "更新に失敗する場合" do
      it "show テンプレートをレンダリング (unprocessable_content) すること" do
        allow_any_instance_of(Game).to receive(:update).and_return(false)

        patch game_path(game), params: { game: { description: "updated text" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /games/:id/check_generated_image" do
    context "画像がアタッチされていない場合" do
      it "204 No Content を返すこと" do
        allow_any_instance_of(Game).to receive_message_chain(:generated_image, :attached?).and_return(false)

        get check_generated_image_game_path(game)
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe "GET /games/:id/check_score" do
    context "feedback が存在する場合" do
      before do
        game.update!(feedback: "Great job!")
      end

      it "Turbo Stream レスポンスを返すこと" do
        get check_score_game_path(game), as: :turbo_stream
        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response).to have_http_status(:success)
      end
    end

    context "feedback が存在しない場合" do
      before do
        game.update!(feedback: nil)
      end

      it "204 No Content を返すこと" do
        get check_score_game_path(game)
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe "GET /games/:id/score" do
    it "FeedbackJob をエンキューし、正常にレスポンスを返すこと" do
      expect {
        get score_game_path(game)
      }.to have_enqueued_job(FeedbackJob).with(game, "English", "Japanese")

      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /games/:id" do
    let!(:game_to_delete) { create(:game) }

    it "レコードを削除し、root_path にリダイレクトすること" do
      expect {
        delete game_path(game_to_delete)
      }.to change(Game, :count).by(-1)

      expect(response).to redirect_to(root_path)
    end
  end
end
