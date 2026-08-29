import { Controller } from '@hotwired/stimulus';
import TurndownService from 'turndown';

export default class extends Controller {
  static targets = ['source', 'button'];

  copy() {
    // コピーしたくない要素を取り除く処理
    // 元の要素はそのまま残し、複製を作る
    const clone = this.sourceTarget.cloneNode(true);
    // 複製の中から、除外したい要素だけをすべて削除
    clone.querySelectorAll(".no-copy").forEach((el) => el.remove());
    // 加工後の複製からテキストを取得してコピー
    navigator.clipboard.writeText(clone.innerText);

    // マークダウンに変換する処理
    const turndownService = new TurndownService();
    const markdown = turndownService.turndown(clone.innerHTML);

    navigator.clipboard.writeText(markdown).then(() => {
      this.showCopied();
    });
  }

  showCopied() {
    const original = this.buttonTarget.innerHTML;

    const checkIconSvg = `
      <div class="tooltip tooltip-open" data-tip="コピーしました">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-6 h-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
        </svg>
      </div>
    `;
    this.buttonTarget.innerHTML = checkIconSvg;
    /*this.buttonTarget.textContent = 'コピーしました!';*/
    setTimeout(() => {
      this.buttonTarget.innerHTML = original;
    }, 1000);
  }
}
