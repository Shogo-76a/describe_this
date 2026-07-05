import { Controller } from "@hotwired/stimulus"
import { themeChange } from "theme-change"

// Connects to data-controller="theme-select"
export default class extends Controller {
  connect() {
      // ローカルストレージ、または <html> タグから現在のテーマを取得
      const savedTheme = localStorage.getItem("theme") || document.documentElement.getAttribute("data-theme")
      
      if (savedTheme) {
        // <html> タグにテーマを適用
        document.documentElement.setAttribute("data-theme", savedTheme)
        // セレクトボックスの表示を合わせる
        this.element.value = savedTheme
      }
    }

    // セレクトボックスが切り替えられたときに動く処理
    change(event) {
      const selectedTheme = event.target.value

      // <html> タグの data-theme を書き換える（これで色が変わります）
      document.documentElement.setAttribute("data-theme", selectedTheme)

      // 次回アクセス時やページ遷移時のためにローカルストレージに保存
      localStorage.setItem("theme", selectedTheme)
    }
  }