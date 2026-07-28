if Rails.env.development?
  require "bullet" rescue nil

  Bullet.enable = true
  Bullet.bullet_logger = true   # log/bullet.log に出す
  Bullet.rails_logger = true    # development.log にも出す
  Bullet.console = true         # ブラウザの DevTools コンソールに出す
  Bullet.add_footer = true      # HTML フッターに出す
  Bullet.alert = false          # alert() を出すなら true
  Bullet.raise = false          # true にすると例外で止める（開発でのみ）

  # safelist / whitelist を追加する例
  safelists = [
    { type: :n_plus_one_query, class_name: "User", association: :profile },
    { type: :unused_eager_loading, class_name: "Post", association: :comments }
  ]

  safelists.each do |entry|
    if Bullet.respond_to?(:add_safelist)
      # modern API
      Bullet.add_safelist(**entry)
    elsif Bullet.respond_to?(:add_whitelist)
      # old API (互換）
      Bullet.add_whitelist(**entry)
    else
      Rails.logger.info "Bullet: safelist/whitelist API not available on this version"
    end
  end
end