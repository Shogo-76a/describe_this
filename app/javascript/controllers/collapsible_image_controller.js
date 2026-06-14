import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wrapperGlobal", "wrapperA", "wrapperB" ]

  connect() {
    // resize イベントを監視する関数をバインド（登録解除できるように変数化）。thisの参照を固定化する。
    this.onResize = this.updateLayout.bind(this)
    window.addEventListener("resize", this.onResize)

    // 初回読み込み時のレイアウト調整
    this.updateLayout()
  }

  // Turboのページ遷移などで要素が消えるときにイベント監視を解除（メモリリーク対策）
  disconnect() {
    window.removeEventListener("resize", this.onResize)
  }

  activateA() {
    if (this.isWideScreen) return
    this.wrapperATarget.classList.add("w-7/8", "z-10")
    this.wrapperATarget.classList.remove("w-1/8")
    this.wrapperBTarget.classList.add("w-1/8")
    this.wrapperBTarget.classList.remove("w-7/8", "z-10")
  }

  activateB() {
    if (this.isWideScreen) return
    this.wrapperBTarget.classList.add("w-7/8", "z-10")
    this.wrapperBTarget.classList.remove("w-1/8")
    this.wrapperATarget.classList.add("w-1/8")
    this.wrapperATarget.classList.remove("w-7/8", "z-10")
  }

  get isWideScreen() {
    return window.innerWidth >= 640
  }

  updateLayout() {
    if (this.isWideScreen) {
      // 横画面以上の時：Stimulusが付与した縦画面用のクラスをリセット
      this.wrapperGlobalTarget.classList.remove("relative", "aspect-[800/600]", "overflow-hidden", "w-7/8", "w-1/8", "z-10")
      this.wrapperATarget.classList.remove("absolute", "top-0", "left-0", "h-full", "transition-all", "duration-500", "ease-in-out", "w-7/8", "w-1/8", "z-10")
      this.wrapperBTarget.classList.remove("absolute", "top-0", "right-0", "h-full", "transition-all", "duration-500", "ease-in-out", "w-7/8", "w-1/8", "z-10")
    } else {
      // 縦画面に戻った時：クラスを再付与できるように初期化してAを展開
      // ※これを入れないと、横画面から縦画面に「戻した」ときに absolute などが消えたまま崩れる
      this.wrapperGlobalTarget.classList.add("relative", "aspect-[800/600]", "overflow-hidden")
      this.wrapperATarget.classList.add("absolute", "top-0", "left-0", "h-full", "transition-all", "duration-500", "ease-in-out")
      this.wrapperBTarget.classList.add("absolute", "top-0", "right-0", "h-full", "transition-all", "duration-500", "ease-in-out")
      
      this.activateA()
    }
  }
}