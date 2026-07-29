class ThemeImagePicker
  DEFAULT_FOLDER = "describe_this/theme_images"
  FALLBACK_GRAY = "placeholder_gray.png"
  FALLBACK_WHITE = "placeholder_white.png"

  def initialize(folder: DEFAULT_FOLDER, seed: nil)
    @folder = folder
    @seed = seed || SecureRandom.uuid
  end

  # 戻り値: 画像の URL（String）
  def call
    seed_int = @seed.hash
    images = CloudinaryFolderService.fetch_images_from_folder(@folder)

    if images.any?
      random_generator = Random.new(seed_int)
      selected_id = images.sample(random: random_generator)
      Cloudinary::Utils.cloudinary_url(
        selected_id,
        width: 600, height: 400, crop: :fill, fetch_format: :auto, quality: :auto
      )
    else
      FALLBACK_GRAY
    end
  rescue => e
    Rails.logger.error("ThemeImagePicker Error: #{e.message}")
    FALLBACK_WHITE
  end
end