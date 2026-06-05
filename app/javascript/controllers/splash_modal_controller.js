import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    // セッションストレージを確認（すでに表示済みなら何もしない）
    if (sessionStorage.getItem("modal_displayed")) {
      return
    }

    this.appContent = document.querySelector(".app-content")

    // ローディング状態をチェックして出し分け
    if (!this.appContent.classList.contains("loading")) {
      this.openModalAndSaveFlag()
    } else {
      this.observeLoadingRemoval()
    }
  }

  // ページ遷移したとき/このstimulusコントローラが DOM から削除されたとき、this.observerを安全に切断してメモリリークを防ぐ。
  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  // 変化があったページ要素のクラスに loading があるかを監視。なければ監視を切断する。
  observeLoadingRemoval() {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === "class") {
          const currentClass = mutation.target.className
          
          if (!currentClass.includes("loading")) {
            this.openModalAndSaveFlag()
            this.observer.disconnect()
          }
        }
      })
    })

    this.observer.observe(this.appContent, { attributes: true })
  }

  // モーダルを表示し、表示済みフラグをセッションに保存する
  openModalAndSaveFlag() {
    if (this.hasDialogTarget) {
      this.dialogTarget.showModal()
      // フラグを保存（ブラウザのタブを閉じるまで有効）
      sessionStorage.setItem("modal_displayed", "true")
    }
  }
}