import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-feedback"
export default class extends Controller {
  static targets = [ "message" ]

  removeFirst() {
    // 1番上のメッセージ要素を取得 (配列の0番目)
    const firstMessage = this.messageTargets[0]

    if (firstMessage) {
      // 要素をブラウザのDOMから完全に削除
      firstMessage.remove()
    }
  }
}
