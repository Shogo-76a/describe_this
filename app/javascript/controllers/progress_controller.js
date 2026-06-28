import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="progress"
export default class extends Controller {
  static targets = ["progressNum"]

  // アニメーションのタイマーを管理する変数
  animationFrameId = null

  disconnect() {
    // 画面遷移時にアニメーションが走っていたら停止させる（メモリリーク防止）
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }
  }

  handleUpdate(event) {
    const targetValue = parseInt(event.detail.value, 10)
    this.animateTo(targetValue)
  }

  animateTo(targetValue) {
    // 既に動いているアニメーションがあれば一度止める
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }

    // 現在のゲージの値をCSSから取得（初期値は0）
    let currentValue = parseInt(this.element.style.getPropertyValue("--value")) || 0
    
    // アニメーションの速度調整
    const step = 1

    const loop = () => {
      if (currentValue < targetValue) {
        // 目標値より小さければ増やす
        currentValue = Math.min(currentValue + step, targetValue)
      }
      // 1%ずつ書き換え
      this.element.style.setProperty("--value", currentValue)

      // 目標値に達していなければ、次のフレームでもループを継続
      if (currentValue !== targetValue) {
        this.animationFrameId = requestAnimationFrame(loop)
      } else {
        // ループ完了時の処理
        this.progressNumTarget.classList.remove("hidden")
        //hidden 削除後に requestAnimationFrame で透明度を切り替えることで、フェードアニメーションを有効化。
        requestAnimationFrame(() => {
          this.progressNumTarget.classList.remove("opacity-0")
          this.progressNumTarget.classList.add("opacity-100")
        })
      }
    }

    // ループ処理を開始
    this.animationFrameId = requestAnimationFrame(loop)
  }
}