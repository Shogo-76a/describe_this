import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-form"
export default class extends Controller {
  // 送信が成功したら入力を空にする
  clear() {
    this.element.reset()
  }
}
