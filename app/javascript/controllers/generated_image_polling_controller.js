import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js" // Rails標準の軽量Fetchライブラリ

// Connects to data-controller="generated-image-polling"
export default class extends Controller {
  static values = {
    url: String,
    maxAttempts: Number,
    interval: Number
  }

  connect() {
    this.attempts = 0
    this.checkRecord()
  }

  disconnect() {
    this.stopPolling()
  }

  async checkRecord() {
    this.attempts++
    console.log(`ポーリング中... 回数: ${this.attempts}`);

    // サーバーへリクエストを送信
    const response = await get(this.urlValue, { responseKind: "turbo-stream" })

    // 200 OK（画像が添付されていて、Turbo Stream が返ってきた場合）
    if (response.statusCode === 200) {
      console.log("画像が生成されました！画面を更新し、ポーリングを停止します。");
      this.stopPolling() // ここでループを終了
    } 
    
    // 204 No Content（レコードはあるが、画像はまだ生成中の場合）
    else if (response.statusCode === 204) {
      if (this.attempts >= this.maxAttemptsValue) {
        console.log("タイムアウトしました。");
        this.stopPolling()
        this.handleFailure()
      } else {
        console.log("画像はまだ未添付です。数秒後に再確認します。");
        this.timeoutId = setTimeout(() => this.checkRecord(), this.intervalValue + 4000)
      }
    } 
    
    // その他のエラー
    else {
      console.error("予期せぬエラーが発生しました:", response.statusCode);
      this.stopPolling()
    }
  }

  stopPolling() {
    if (this.timeoutId) clearTimeout(this.timeoutId)
  }

  handleFailure() {
    // 例外処理：エラーメッセージへの差し替えなど
    this.element.innerHTML = "<p class='text-error'>画像生成タイムアウトが発生しました。再試行してください。</p>"
  }
}
