import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "link" ]

  connect() {
    this.setActiveTab()
  }

  setActiveTab() {
    // 現在のURLのパスを取得 (例: "/" や "/search")
    const currentPath = window.location.pathname

    this.linkTargets.forEach((element) => {
      // リンク先URLのパス部分だけを抽出
      const linkPath = new URL(element.href, window.location.origin).pathname

      // '#' リンクの時は判定をスキップして非アクティブにする
      if (element.getAttribute("href") === "#") {
        element.classList.remove("active", "text-primary", "hover:text-base-content/90", "transition-all")
        element.classList.add("text-base-content/60")
        return
      }
      // 現在のパスとリンク先のパスが一致するか判定
      if (currentPath === linkPath) {
        element.classList.add("active", "text-primary", "font-black")
        element.classList.remove("text-base-content/60", "hover:text-base-content/90", "transition-all")
      } else { 
        element.classList.add("text-base-content/60", "hover:text-base-content/90", "transition-all")
        element.classList.remove("active", "text-primary", "font-black")
      }
    })
  }
}