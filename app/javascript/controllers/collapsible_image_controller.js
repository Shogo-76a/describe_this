import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wrapperGlobal", "wrapperA", "wrapperB", "submitButton" ]

  connect() {
    // 初期状態は A をアクティブに設定
    this.activeImage = "A"

    this.onResize = this.updateLayout.bind(this)
    window.addEventListener("resize", this.onResize)
    this.updateLayout()
  }

  disconnect() {
    window.removeEventListener("resize", this.onResize)
  }

  // タップするたびに A と B を交互に切り替える
  toggle() {
    if (this.isWideScreen) return // 横画面以上なら何もしない

    if (this.activeImage === "A") {
      this.activateB()
    } else {
      this.activateA()
    }
  }

  activateA() {
    this.activeImage = "A"
    this.wrapperATarget.classList.add("w-39/40", "z-10")
    this.wrapperATarget.classList.remove("w-1/40")
    this.wrapperBTarget.classList.add("w-1/40")
    this.wrapperBTarget.classList.remove("w-39/40", "z-10")
  }

  activateB() {
    this.activeImage = "B"
    this.wrapperBTarget.classList.add("w-39/40", "z-10")
    this.wrapperBTarget.classList.remove("w-1/40")
    this.wrapperATarget.classList.add("w-1/40")
    this.wrapperATarget.classList.remove("w-39/40", "z-10")
  }

  get isWideScreen() {
    return window.innerWidth >= 640
  }

  updateLayout() {
    if (this.isWideScreen) {
      // 横画面以上の時：Stimulusが付与した縦画面用のクラスをリセット
      this.wrapperGlobalTarget.classList.remove("relative", "aspect-[800/600]", "overflow-hidden", "w-39/40", "w-1/40", "z-10")
      this.wrapperATarget.classList.remove("absolute", "top-0", "left-0", "h-full", "transition-all", "duration-500", "ease-in-out", "w-39/40", "w-1/40", "z-10")
      this.wrapperBTarget.classList.remove("absolute", "top-0", "right-0", "h-full", "transition-all", "duration-500", "ease-in-out", "w-39/40", "w-1/40", "z-10")
    } else {
      // 縦画面に戻った時：クラスを再付与できるように初期化してAを展開
      // ※これを入れないと、横画面から縦画面に「戻した」ときに absolute などが消えたまま崩れる
      this.wrapperGlobalTarget.classList.add("relative", "aspect-[800/600]", "overflow-hidden")
      this.wrapperATarget.classList.add("absolute", "top-0", "left-0", "h-full", "transition-all", "duration-500", "ease-in-out")
      this.wrapperBTarget.classList.add("absolute", "top-0", "right-0", "h-full", "transition-all", "duration-500", "ease-in-out")
      
      this.activateA()
    }
  }


  // コントローラ自体の初期化時だけでなく、
  // Turbo Stream等でこのターゲット要素が「画面に現れた瞬間」に毎回自動で動く
  submitButtonTargetConnected(element) {
    const isDisabled = element.disabled
    console.log(`[Target接続] ボタンが新しく届きました。disabled: ${isDisabled}`)

    if (isDisabled) {
      // 無効時の処理
      return
    } else {
      // 有効時の処理
      if (this.activeImage === "A") {
      this.toggle() 
    } else {
      return
      }
    }
  }
}