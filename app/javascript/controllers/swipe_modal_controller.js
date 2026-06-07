import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="swipe-modal"
export default class extends Controller {
  // HTML要素をターゲットとして登録
  static targets = ["carousel", "actionBtn", "dot"]
  
  connect() {
    this.currentIndex = 0
    this.totalSlides = this.dotTargets.length
    this.updateUI()
    this.isProgrammaticScroll = false // ボタンからのスクロールかどうかを判定するフラグ。UI更新時のチラつき防止用。
  }

  // 「つぎへ / とじる」ボタンがクリックされたとき
  nextOrClose(event) {
    event.preventDefault()
    this.isProgrammaticScroll = true // ロックをかける。UI更新時のチラつき防止。

    if (this.currentIndex < this.totalSlides - 1) {
      // 次のスライドへスクロール
      this.currentIndex++
      this.scrollToCurrentIndex()
      this.updateUI()

      // アニメーションが終わる頃（約300〜400ms後）にロックを解除する
      setTimeout(() => {
        this.isProgrammaticScroll = false
      }, 400) // smoothスクロールの時間に合わせて調整

    } else {
      // 最後のページならモーダルを閉じる
      this.element.close() // <dialog> 要素自体にコントローラーを付けるため this.element で閉じる
      
      
      // 次回開いた時のために最初のページにリセット
      setTimeout(() => {
        this.currentIndex = 0
        this.scrollToCurrentIndex()
        this.updateUI()
      }, 300) // モーダルが閉じるアニメーションを待ってリセット
    }
  }

  
  // ユーザーが直接手動でスワイプ（スクロール）したとき
  handleScroll() {

    // ボタン操作によるスクロール中なら、途中の細かい位置計算はすべて無視する。
    if (this.isProgrammaticScroll) return

    const slideWidth = this.carouselTarget.offsetWidth
    const newIndex = Math.round(this.carouselTarget.scrollLeft / slideWidth)

    if (newIndex !== this.currentIndex && newIndex >= 0 && newIndex < this.totalSlides) {
      this.currentIndex = newIndex
      this.updateUI()
    }
  }

  // 指定のインデックス位置へスクロールさせるヘルパー
  scrollToCurrentIndex() {
    const slideWidth = this.carouselTarget.offsetWidth
    this.carouselTarget.scrollTo({
      left: slideWidth * this.currentIndex,
      behavior: 'smooth'
    })
  }

  // 現在のインデックスに応じてUI（ボタン・ドット）を更新
  updateUI() {
    // ボタンのテキストと見た目の切り替え
    if (this.currentIndex === this.totalSlides - 1) {
      this.actionBtnTarget.innerText = "とじる"
    } else {
      this.actionBtnTarget.innerText = "つぎへ"
    }

    // ドットインジケーターのアクティブ状態の切り替え
    this.dotTargets.forEach((dot, idx) => {
      if (idx === this.currentIndex) {
        dot.classList.remove("bg-base-300")
        dot.classList.add("bg-primary")
      } else {
        dot.classList.remove("bg-primary")
        dot.classList.add("bg-base-300")
      }
    })
  }


}