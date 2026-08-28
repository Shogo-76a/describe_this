# 採点ページ用のヘルパーメソッド置き場
module ScoreHelper
  # スコアに応じて テキストとHTMLの見た目を返すHTMLを作成する。
  def render_score_badge(score)
    result = ScoreEvaluator.call(score)

    # DaisyUIクラスとスタイルを合成してHTMLタグを生成
    # 次の要素を返す「 <div class=""#{result[:color]} #{result[:style]}"> result[:label] </div> 」
    tag.div(
      result[:label],
      class: "#{result[:style]}"
    )
  end
end
