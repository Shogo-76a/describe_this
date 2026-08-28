# 採点ページ_判定ロジック。スコアに応じた テキストとスタイルを返す。
class ScoreEvaluator
  CONFIGS = [
    { range: 95..100, label: "Perfect!!!", style: "italic text-6xl tracking-widest opacity-100 font-black" },
    { range: 85..94,   label: "Amazing!!",  style: "italic text-6xl tracking-normal opacity-90 font-extrabold" },
    { range: 75..84,   label: "Great!",     style: "italic text-6xl tracking-normal opacity-80 font-bold" },
    { range: 70..74,   label: "Good",       style: "italic text-5xl tracking-normal opacity-70 font-medium" },
    { range: 50..69,   label: "Okay",       style: "italic text-5xl tracking-tighter opacity-60 font-normal" },
    { range: 0..49,    label: "Needs Work", style: "italic text-3xl tracking-tighter opacity-50 font-extralight" }
  ].freeze

  def self.call(score)
    score_num = score.to_i
    CONFIGS.find { |config| config[:range].cover?(score_num) } || CONFIGS.last
  end
end
