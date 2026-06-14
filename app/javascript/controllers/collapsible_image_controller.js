import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wrapperGlobal", "wrapperA", "wrapperB" ]

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
      // 横画面以上の時（画像1枚ずつの比率を 800:600 で完全固定）
      this.wrapperGlobalTarget.classList.add("relative") 
      this.wrapperGlobalTarget.classList.remove("aspect-[800/600]", "overflow-hidden")

      this.wrapperATarget.classList.remove("absolute", "top-0", "left-0", "h-full", "transition-all", "duration-500", "ease-in-out", "w-39/40", "w-1/40", "z-10")
      this.wrapperATarget.classList.add("relative", "w-1/2", "aspect-[800/600]") // ★比率を固定

      this.wrapperBTarget.classList.remove("absolute", "top-0", "right-0", "h-full", "transition-all", "duration-500", "ease-in-out", "w-39/40", "w-1/40", "z-10")
      this.wrapperBTarget.classList.add("relative", "w-1/2", "aspect-[800/600]") // ★比率を固定
      
    } else {
      // 縦画面に戻った時
      this.wrapperGlobalTarget.classList.add("relative", "aspect-[800/600]", "overflow-hidden")
      
      this.wrapperATarget.classList.remove("relative", "w-1/2", "aspect-[800/600]")
      this.wrapperBTarget.classList.remove("relative", "w-1/2", "aspect-[800/600]")

      this.wrapperATarget.classList.add("absolute", "top-0", "left-0", "h-full", "transition-all", "duration-500", "ease-in-out")
      this.wrapperBTarget.classList.add("absolute", "top-0", "right-0", "h-full", "transition-all", "duration-500", "ease-in-out")
      
      // 保持していた現在の状態に合わせて展開
      if (this.activeImage === "A") {
        this.activateA()
      } else {
        this.activateB()
      }
    }
  }
}