import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-message"
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.triggerAutoMessage()
  }

  async triggerAutoMessage() {
    try {
      // URLの末尾に .turbo_stream を強制付与して、確実に show の format.turbo_stream を呼び出す
      const urlWithFormat = this.urlValue.includes('?') 
        ? this.urlValue.replace('?', '.turbo_stream?') 
        : `${this.urlValue}.turbo_stream`

      const response = await fetch(urlWithFormat, {
        method: "GET",
        headers: { "Accept": "text/html; turbo-stream.html" }
      })

      if (response.ok) {
        const html = await response.text()
        // サーバーから返ってきた Turbo Stream 指示を実行
        Turbo.renderStreamMessage(html)
      } else {
        console.error(`サーバーエラー: ${response.status}`)
      }
    } catch (error) {
      console.error("自動メッセージの取得に失敗しました:", error)
    }
  }
}