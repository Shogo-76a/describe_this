import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js" // Rails標準の軽量Fetchライブラリ

// Connects to data-controller="score-polling"
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

    // 200 OK（採点が完了していて、Turbo Stream が返ってきた場合）
    if (response.statusCode === 200) {
      console.log("採点完了しました！画面を更新し、ポーリングを停止します。");
      this.stopPolling() // ここでループを終了
    } 
    
    // 204 No Content（レコードはあるが、まだ採点中の場合）
    else if (response.statusCode === 204) {
      if (this.attempts >= this.maxAttemptsValue) {
        console.log("タイムアウトしました。");
        this.stopPolling()
        this.handleFailure()
      } else {
        console.log("まだ採点中です。数秒後に再確認します。");
        this.timeoutId = setTimeout(() => this.checkRecord(), this.intervalValue)
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
    this.element.innerHTML = "<p class='text-error'>採点表示のタイムアウトが発生しました。再試行してください。</p>"
  }
}

