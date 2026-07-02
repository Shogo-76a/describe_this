import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-feedback"
export default class extends Controller {
  static targets = [ "message" ]

  connect() {
    setTimeout(() => {
      this.removeHiddenOneByOne()
        }, 2000)
  }

  removeFirst() {
    // 1番上のメッセージ要素を取得 (配列の0番目)
    const firstMessage = this.messageTargets[0]

    if (firstMessage) {
      // 要素をブラウザのDOMから完全に削除
      firstMessage.remove()
    }
  }

  removeHiddenOneByOne() {
    const lastIndex = this.messageTargets.length - 1;

    this.messageTargets.forEach((message, index) => {
      setTimeout(() => {
        message.classList.remove("hidden");

        // もし現在の要素が「最後の要素」だったら処理を実行
        if (index === lastIndex) {
          this.afterAllMessagesShown(message);
        }

      }, index * 1000);
    });
  }

  // すべて表示された後に実行したい処理
  afterAllMessagesShown(lastMessage) {
    console.log("すべてのメッセージが表示されました！");
    // 例：最新のメッセージまで自動スクロールする
    lastMessage.scrollIntoView({ behavior: "smooth" });
    lastMessage.classList.add("hidden");
  }
  
}