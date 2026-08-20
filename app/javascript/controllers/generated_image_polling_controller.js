import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js'; // Rails標準の軽量Fetchライブラリ

// Connects to data-controller="generated-image-polling"
export default class extends Controller {
  static values = {
    url: String,
    maxAttempts: Number,
    interval: Number,
  };

  connect() {
    this.attempts = 0;
    this.timeoutId = null;
    this.since = null;
    // connect時は checkRecord() を呼ばない
    // 画像生成ページで テキスト送信後にポーリング開始
    this.element.addEventListener('turbo:submit-end', () => {
      // 送信が完了した時点のタイムスタンプを発行する（since変数）
      // サーバー側（games_controller）で添付画像の作成時刻とsinceを比較し、sinceが新しければポーリングを実行する。
      this.since = new Date().toISOString();
      this.attempts = 0; // 再送時は試行回数をリセット
      this.stopPolling(); // 既存のタイマーがあればクリア
      this.startPolling();
    });
  }

  disconnect() {
    this.stopPolling();
  }

  startPolling() {
    // フォーム送信完了後、ポーリング開始
    this.checkRecord();
  }

  async checkRecord() {
    this.attempts++;
    console.log(`ポーリング中... 回数: ${this.attempts}`);

    // サーバーへリクエストを送信
    // Stimulus側で this.since をセットして GET リクエストの URL に ?since=... を付けているので、Rails 側では params[:since] として受け取れる。
    const url = this.since ? `${this.urlValue}?since=${encodeURIComponent(this.since)}` : this.urlValue;
    const response = await get(url, { responseKind: 'turbo-stream' });

    // 200 OK（画像が添付されていて、Turbo Stream が返ってきた場合）
    if (response.statusCode === 200) {
      console.log(
        '画像が生成されました！画面を更新し、ポーリングを停止します。',
      );
      this.stopPolling(); // ここでループを終了
    }

    // 204 No Content（レコードはあるが、画像はまだ生成中の場合）
    else if (response.statusCode === 204) {
      if (this.attempts >= this.maxAttemptsValue) {
        console.log('タイムアウトしました。');
        this.stopPolling();
        this.element.innerHTML =
          "<p class='text-error'>画像生成タイムアウトが発生しました。再試行してください。</p>";
      } else {
        console.log('画像はまだ未添付です。数秒後に再確認します。');
        this.timeoutId = setTimeout(
          () => this.checkRecord(),
          this.intervalValue,
        );
      }
    }

    // その他のエラー
    else {
      console.error('予期せぬエラーが発生しました:', response.statusCode);
      this.stopPolling();
      this.element.innerHTML =
        "<p class='flex items-center justify-center text-error'>予期せぬエラーが発生しました。<br>数分後にアプリを再起動してください。</p>";
    }
  }

  stopPolling() {
    if (this.timeoutId) clearTimeout(this.timeoutId);
    this.timeoutId = null;
  }
}
