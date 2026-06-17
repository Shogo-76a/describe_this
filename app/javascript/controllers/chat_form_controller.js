// app/javascript/controllers/chat_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]


  // 入力欄の高さを 改行など があったときに自動調整するメソッド
  resize() {
    const textarea = this.textareaTarget
    
    // 一度高さを初期化（リセットしないと、文字を消したときに縮まなくなります）
    textarea.style.height = "40px"
    
    // スクロールする高さ（文字全体の高さ）を取得
    const scrollHeight = textarea.scrollHeight
    
    // 最大で 150px（約5〜6行分）まで伸びるように制限をかけつつ自動調整
    if (scrollHeight <= 150) {
      textarea.style.height = `${scrollHeight}px`
      textarea.style.overflowY = "hidden" // スクロールバーを隠す
    } else {
      textarea.style.height = "150px"
      textarea.style.overflowY = "auto" // 150pxを超えたらスクロールさせる
    }
  }


  // キーボードが押されたときに発火するメソッド
  handleKeydown(event) {
    // 変換確定時のEnter（日本語入力の確定など）はスルーする
    if (event.isComposing || event.keyCode === 229) return

    // スマホ（タッチデバイス）の場合：Enterは「常に改行」にする
    const isMobile = window.matchMedia("(pointer: coarse)").matches

    if (isMobile) {
      // スマホではEnter単体でも、送信せず普通の改行として振る舞わせるため
      // ここでは何もしない（標準のフォーム送信を発生させない）
      return
    }

    // 2. パソコン（PC）の場合の挙動制御
    if (event.key === "Enter") {
      if (event.shiftKey) {
        // Shift + Enter の場合は「改行」したいので、送信をスルー（普通の挙動）
        return
      } else {
        // Enter単体の場合は「送信」したい
        event.preventDefault() // 通常の改行挙動をストップ
        this.element.requestSubmit() // フォームをプログラムから送信
      }
    }
  }

  // 送信が成功したら入力を空にする
  clear() {
    this.element.reset()
    this.resize()
  }
}