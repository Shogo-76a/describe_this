import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 初回訪問かチェック
    if (!sessionStorage.getItem('visited')) {
      this.showIntro()
      sessionStorage.setItem('visited', 'true')
    } else {
      // 2回目以降の訪問時は、loading クラスを削除
      this.hideLoadingImmediately()
    }
  }

  showIntro() {
    // hidden クラスを削除して導入画面を表示
    this.element.classList.remove('hidden')
    // 3秒後にフェードアウト
    setTimeout(() => {
      this.hideIntro()
    }, 3000)
  }

  hideIntro() {
    // フェードアウト開始
    this.element.classList.add('fade-out')
    // アニメーション終了後に要素を削除し、loading クラスを削除
    this.element.addEventListener('transitionend', () => {
      this.element.remove()
      this.showAppContent()
    }, { once: true })
  }

  hideLoadingImmediately() {
    // 2回目以降の訪問時は、導入画面を表示せずにすぐにコンテンツを表示
    this.element.remove()
    this.showAppContent()
  }

  showAppContent() {
    // アプリコンテンツの loading クラスを削除
    const appContent = document.querySelector('.app-content')
    if (appContent) {
      appContent.classList.remove('loading')
    }
  }
}
