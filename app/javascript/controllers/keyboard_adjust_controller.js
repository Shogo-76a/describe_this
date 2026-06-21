import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="keyboard-adjust"
export default class extends Controller {
  connect() {
    if (window.visualViewport) {
      window.visualViewport.addEventListener("resize", this.handleResize)
      window.visualViewport.addEventListener("scroll", this.handleResize)
    }
  }

  disconnect() {
    if (window.visualViewport) {
      window.visualViewport.removeEventListener("resize", this.handleResize)
      window.visualViewport.removeEventListener("scroll", this.handleResize)
    }
  }

  handleResize = () => {
    // Safariの描画タイミングに合わせることでガタつきを減らす
    requestAnimationFrame(() => {
      const inputBar = document.getElementById("fixed-input-bar")
      if (!inputBar) return

      const viewport = window.visualViewport
      const fullHeight = window.innerHeight
      
      // キーボードの高さを計算
      const bottomOffset = fullHeight - viewport.height - viewport.offsetTop

      // iPhoneの底部セーフエリア（バー）の考慮
      inputBar.style.bottom = `${Math.max(0, bottomOffset)}px`
    })
  }
}