module ApplicationHelper
  # ゲーム内言語設定に応じて言語名テキストを返す。テキストはI18n対応済み。
  def render_locale_name(target_locale)
    TextSelectorOnLocale.call(target_locale)
    # 文字列が返る
  end
end
