class CloudinaryFolderService
  def self.fetch_images_from_folder(folder_name)
    # 頻繁なAPIリクエストを防ぐため、1時間キャッシュする
    Rails.cache.fetch("cloudinary_folder_#{folder_name}", expires_in: 1.hour) do
      # CloudinaryのSearch APIを呼び出す
      result = Cloudinary::Search
                .expression("folder:#{folder_name} AND resource_type:image")
                .max_results(50) # 必要に応じて調整
                .execute

      # 画像の public_id（または外部URL）の配列を返す
      result["resources"].map { |resource| resource["public_id"] }
    end
  rescue => e
    Rails.logger.error "Cloudinary Fetch Error: #{e.message}"
    [] # エラー時は空配列をコントローラ側に返す
  end
end