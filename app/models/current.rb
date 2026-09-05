class Current < ActiveSupport::CurrentAttributes
  # ユーザー認証用
  attribute :session
  delegate :user, to: :session, allow_nil: true

  # ゲーム内使用言語
  attribute :locale_in_game

  # 入力テキストの言語判定に使用
  attribute :allowed_languages
  attribute :mode

end
