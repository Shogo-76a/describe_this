# インゲーム言語に応じた表示判定ロジック。jaの場合はJapaneseを返す。i18n対応。
class TextSelectorOnLocale

  # ここではI18nを設定しない。メソッドで呼び出されないので、I18nが反映できない。
  LOCALES  = {
    "ja" => "language.Japanese",
    "en" => "language.English"
  }.freeze

  def self.call(target_locale)
    target = target_locale.to_s
    translation_key = LOCALES[target]
    
    # ここでI18nを設定。メソッドで呼び出されたタイミングでI18nを取得する
      # "language.Japanese"がt()にそのまま入ることで、I18nのキーワードと合致する。
    I18n.t(translation_key) if translation_key
  end

  def self.call_no_i18n(target_locale)
    target = target_locale.to_s
    LOCALES[target] 
    LOCALES[target].split('.').last  #　AIプロンプト用。"Japanese" などのアルファベット名で返す。I18nをしない。
  end
end
