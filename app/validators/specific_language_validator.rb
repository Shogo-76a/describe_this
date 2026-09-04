class SpecificLanguageValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # record    => 現在保存しようとしているモデルのインスタンス（例: #<Post id: nil, content: "...">）
    # attribute => バリデーション対象のカラム名（シンボル。例: :content）
    # value     => 実際にユーザーが入力したテキスト（文字列。例: "Hello, world!"）　取り付けた先（modelカラム）の値が入る。

    return if value.blank?

    # コントローラー側で「言語制限なし(nil)」と判定されたモードなら、ここで即終了（バリデーションを外す）
    return if Current.allowed_languages.nil?

    # バリデーションを実行する（つける）
    detector = CLD3::NNetLanguageIdentifier.new(0, 1000)
    result = detector.find_language(value)

    if result.reliable? && !Current.allowed_languages.include?(result.language.to_s)
      message = options[:message] || "はこのゲームモードでは使用できない言語です。"

      # ここで登録したメッセージがビューに渡る
      record.errors.add(attribute, message)
    end
  end
end