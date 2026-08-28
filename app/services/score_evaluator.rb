# 採点ページ_判定ロジック。スコアに応じた テキストとスタイルを返す。
class ScoreEvaluator
  CONFIGS = [
    { range: 100..100, label: "Perfect!!!", style: "italic text-6xl tracking-widest opacity-100 font-black" },
    { range: 90..99,   label: "Amazing!!",  style: "italic text-6xl tracking-normal opacity-90 font-extrabold" },
    { range: 80..89,   label: "Great!",     style: "italic text-6xl tracking-normal opacity-80 font-bold" },
    { range: 60..79,   label: "Good",       style: "italic text-5xl tracking-normal opacity-70 font-medium" },
    { range: 40..59,   label: "Okay",       style: "italic text-5xl tracking-tighter opacity-60 font-normal" },
    { range: 0..39,    label: "Needs Work", style: "italic text-3xl tracking-tighter opacity-50 font-extralight" }
  ].freeze

  def self.call(score)
    score_num = score.to_i
    CONFIGS.find { |config| config[:range].cover?(score_num) } || CONFIGS.last
  end
end
