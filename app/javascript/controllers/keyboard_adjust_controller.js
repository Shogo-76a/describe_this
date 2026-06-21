import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="keyboard-adjust"
export default class extends Controller {
  connect() {
    if (window.visualViewport) {
      // キーボード開閉やスクロール（ズレ防止）のイベントを設定
      window.visualViewport.addEventListener("resize", this.adjustPosition)
      window.visualViewport.addEventListener("scroll", this.adjustPosition)
    }
  }

  disconnect() {
    if (window.visualViewport) {
      window.visualViewport.removeEventListener("resize", this.adjustPosition)
      window.visualViewport.removeEventListener("scroll", this.adjustPosition)
    }
  }

  adjustPosition = () => {
    const inputBar = document.getElementById("fixed-input-bar")
    if (!inputBar) return

    // 画面全体の高さから、見えている範囲の高さ（とズレ）を引く
    const viewportHeight = window.visualViewport.height
    const offsetTop = window.visualViewport.offsetTop
    const fullHeight = window.innerHeight

    // キーボードの高さ分、下からの位置を上げる
    const bottomOffset = fullHeight - viewportHeight - offsetTop

    // 負の数にならないよう調整してCSSを書き換え
    inputBar.style.bottom = `${Math.max(0, bottomOffset)}px`
  }
}