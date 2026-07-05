import { Controller } from "@hotwired/stimulus"
import { themeChange } from "theme-change"

// Connects to data-controller="theme-select"
export default class extends Controller {
  // 親ボタンのアイコン部分と、メニュー項目を取得できるようにします
  static targets = ["activeIcon", "menuItem"]

  connect() {
    const savedTheme = localStorage.getItem("theme") || "light"
    this.updateMenuHighlight(savedTheme)
  }

  // メニュー内の項目がクリックされたときに動く処理
  select(event) {
    const selectedTheme = event.currentTarget.dataset.themeValue
    this.applyTheme(selectedTheme)
  }

  applyTheme(theme) {
    // <html> タグの書き換え（ページ全体のテーマ切り替え）
    document.documentElement.setAttribute("data-theme", theme)
    localStorage.setItem("theme", theme)

    // Cookieにも同じ名前で保存（Railsのサーバー側で読めるようにする）
    // max-age=31536000 で1年間有効
    document.cookie = "theme=${theme}; path=/; max-age=31536000; SameSite=Lax"

    // 親ボタン（タブ）のアイコンを現在のテーマに更新
    if (this.hasActiveIconTarget) {
      // 親ボタンのアイコン部分全体を、現在選択されているメニュー項目のアイコンで差し替える
      // （これによりPartialで描画された完璧なアイコンが親ボタンにコピーされます）
      const selectedMenuItem = this.menuItemTargets.find(item => item.dataset.themeValue === theme)
      if (selectedMenuItem) {
        const iconHtml = selectedMenuItem.querySelector("span[data-theme]").outerHTML
        this.activeIconTarget.innerHTML = iconHtml
      }
    }

    // メニュー内の「アクティブ状態（選択中チェックマーク）」の切り替え
    this.updateMenuHighlight(theme)
  }

  // メニューの中で、現在選択されているテーマのボタンに `active` クラスをつける
  updateMenuHighlight(theme) {
    this.menuItemTargets.forEach(item => {
      if (item.dataset.themeValue === theme) {
        item.classList.add("active") // daisyUIのメニューハイライトクラス。これでチェックマークが表示されます
      } else {
        item.classList.remove("active")
      }
    })
  }
}