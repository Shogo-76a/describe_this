# トップページ用のヘルパーメソッド置き場
module TopHelper
  # スコアに応じて テキストとHTMLの見た目を返すHTMLを作成する。
  def render_locale_name(target_locale)
    TextSelectorOnLocale.call(target_locale)
    # 文字列が返る
  end
end
