import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapsible-image"
export default class extends Controller {
  static targets = [ "wrapperGlobal", "wrapperA", "wrapperB" ]

  connect() {
    this.updateLayout()
  }

  activateA() {
    if (this.isWideScreen) return // ★横画面以上なら何もしない
    this.wrapperATarget.classList.add("w-5/6", "z-10")
    this.wrapperATarget.classList.remove("w-1/6")
    this.wrapperBTarget.classList.add("w-1/6")
    this.wrapperBTarget.classList.remove("w-5/6", "z-10")
  }

  activateB() {
    if (this.isWideScreen) return // ★横画面以上なら何もしない
    this.wrapperBTarget.classList.add("w-5/6", "z-10")
    this.wrapperBTarget.classList.remove("w-1/6")
    this.wrapperATarget.classList.add("w-1/6")
    this.wrapperATarget.classList.remove("w-5/6", "z-10")
  }

  // スマホ横画面（640px）以上かどうかの判定
  get isWideScreen() {
    return window.innerWidth >= 640
  }

  // 画面が回転したときなどのために初期表示を整える
  updateLayout() {
    if (this.isWideScreen) {
      // 横画面以上の時は、Stimulusがつけた余計な幅クラスを消す
      this.wrapperGlobalTarget.classList.remove("relative", "aspect-[800/600]", "overflow-hidden", "w-5/6", "w-1/6", "z-10")
      this.wrapperATarget.classList.remove("absolute", "top-0", "left-0", "h-full", "transition-all", "duration-500", "ease-in-out", "w-5/6", "w-1/6", "z-10")
      this.wrapperBTarget.classList.remove("absolute", "top-0", "right-0", "h-full", "transition-all", "duration-500", "ease-in-out", "w-5/6", "w-1/6", "z-10")
    } else {
      this.activateA() // 縦画面ならAを展開
    }
  }
}