// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// turbo_stream のカスタムアクション。scoring-gauge要素のvalue属性を更新する。
Turbo.StreamActions.update_gauge = function() {
  const value = this.getAttribute("value");
  const element = document.getElementById("scoring-gauge");
  
  if (element) {
    // カスタムイベントを作って要素に送りつける
    const event = new CustomEvent("progress:update", { detail: { value: value } });
    element.dispatchEvent(event);
  }
}