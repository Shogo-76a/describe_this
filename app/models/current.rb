class Current < ActiveSupport::CurrentAttributes
  # ユーザー認証用
  attribute :session
  delegate :user, to: :session, allow_nil: true

  # 入力テキストの言語判定に使用
  attribute :allowed_languages
  attribute :mode

end
