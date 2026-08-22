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
    this.attempts = 0; // ポーリングの回数をカウント
    this.image_success = 0; // 表示成功を判定。成功時は"1"
    this.timeoutId = null;
    this.since = null;
    this.isPollingActive = false; // ポーリングの稼働状態を管理するフラグ

    // 画像生成ページで テキスト送信後にポーリング開始
    this.element.addEventListener('turbo:submit-end', () => {
      // 送信が完了した時点のタイムスタンプを発行する（since変数）
      // サーバー側（games_controller）で添付画像の作成時刻とsinceを比較し、sinceが新しければポーリングを実行する。
      this.since = new Date().toISOString();
      this.attempts = 0; // 再送時は試行回数をリセット
      this.image_success = 0; // 表示判定をリセット
      this.stopPolling(); // 既存のタイマーがあればクリア
      this.startPolling();
    });
  }

  disconnect() {
    // コントローラー破棄時にイベントリスナーを解除
    this.element.removeEventListener('turbo:submit-end', this.handleSubmitEnd);
    this.stopPolling();
  }

  startPolling() {
    this.isPollingActive = true; // ポーリング開始時にフラグをON

    // フォーム送信完了後、ポーリング開始
    this.checkRecord();
  }

  stopPolling() {
    this.isPollingActive = false; // 停止時にポーリングのフラグをOFF（以降の通信をブロック）
    if (this.timeoutId) clearTimeout(this.timeoutId);
    this.timeoutId = null;
  }

  checkImageShown(img) {
    // 既に読み込みが完了しているかチェック
    if (img.complete) {
      this.verifyImage(img);
    } else {
      // 完了していない場合は、load / error イベントで待機する
      img.addEventListener('load', () => this.verifyImage(img));
      img.addEventListener('error', () => {
        console.error('画像の読み込みに失敗（404など）しました');
      });
    }
  }

  // 画像が表示されてるか判定
  verifyImage(img) {

    if (img.naturalWidth === 0) {
      console.log('画像が壊れているか、表示されずaltテキストが表示されています');
      // ※ここで再度 startPolling() を呼ぶと無限ループの危険があります。
      // もしクラウドストレージの反映遅延などで再度ポーリングしたい場合は、
      this.timeoutId = setTimeout(() => this.checkRecord(), this.intervalValue);
      // のようにインターバルを設け、試行回数(attempts)の上限で止まるようにしてください。
    } else {
      console.log('画像が正常に表示されています');
    }
  }

  async checkRecord() {

    this.attempts++;
    console.log(`ポーリング中... 回数: ${this.attempts}`);

    //URLパラメータを作成。サーバーコントローラーに渡す。
    // ベースとなるURLオブジェクトを作成
    const urlObj = new URL(this.urlValue, window.location.origin);
    // image_success（画像生成完了）パラメータを追加。ブーリアンをストリングに変換しておく。
    urlObj.searchParams.set('image_success', this.image_success);
    // since パラメータが存在する場合のみ追加
    // Stimulus側で this.since をセットして GET リクエストの URL に ?since=... を付けているので、Rails 側では params[:since] として受け取れる。
    if (this.since) {
      urlObj.searchParams.set('since', this.since); // URLSearchParamsが自動でURLエンコードしてくれます
    }
    // 完成したURLを文字列として取得
    const url = urlObj.toString();

    const response = await get(url, { responseKind: 'turbo-stream' });

    // 200 OK（画像が添付されていて、Turbo Stream が返ってきた場合）
    if (response.statusCode === 200) {
      console.log(
        '画像が生成されました！画面を更新し、ポーリングを停止します。',
      );
      this.stopPolling(); // ここでループを終了

      this.image_success = 1; // 画像表示成功時に'1'を代入。
      console.log('画像生成完了');

      // 画像が表示されてることをチェックするポーリング。
      setTimeout(() => {
        const imgElement = this.element.querySelector('#checking_image_shown');
        if (imgElement) {
          this.checkImageShown(imgElement);
        } else {
          console.error("要素 '#checking_image_shown' が見つかりませんでした。");
        }
      }, this.intervalValue); // 少し待ってから実行
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
}
