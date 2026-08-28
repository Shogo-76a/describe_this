import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['text'];

  connect() {

    this.scoreElement = this.element.querySelector('#checking_score_shown');

    // スコアゲージ要素にloadingクラスがある状態をチェックして出し分け
    if (!this.scoreElement.classList.contains('loading')) {
      this.showEvaluation();
    } else {
      this.observeLoadingRemoval();
    }
  }

  // ページ遷移したとき/このstimulusコントローラが DOM から削除されたとき、this.observerを安全に切断してメモリリークを防ぐ。
  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  // 変化があったページ要素のクラスに loading があるかを監視。なければ監視を切断する。
  observeLoadingRemoval() {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === 'class') {
          const currentClass = mutation.target.className;

          if (!currentClass.includes('loading')) {
            this.showEvaluation();
            this.observer.disconnect();
          }
        }
      });
    });

    this.observer.observe(this.scoreElement, { attributes: true });
  }

  // モーダルを表示し、表示済みフラグをセッションに保存する
  showEvaluation() {
    if (this.hasTextTarget) {
      //requestAnimationFrame で透明度を切り替えることで、フェードアニメーションを有効化。
      requestAnimationFrame(() => {
        this.textTarget.classList.remove('opacity-0');
        this.textTarget.classList.add('opacity-100');
      });
    }
  }
}
