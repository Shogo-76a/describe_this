import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-feedback"
export default class extends Controller {
  static targets = [ "message", "button" ]

  connect() {
    setTimeout(() => {
      this.removeHiddenOneByOne()
        }, 2000)
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
    this.buttonTarget.classList.remove("hidden");
  }
  
}