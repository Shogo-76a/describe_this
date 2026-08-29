import { Controller } from '@hotwired/stimulus';
import TurndownService from 'turndown';

export default class extends Controller {
  static targets = ['source', 'button'];

  copy() {
    const turndownService = new TurndownService();
    const markdown = turndownService.turndown(this.sourceTarget.innerHTML);

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
