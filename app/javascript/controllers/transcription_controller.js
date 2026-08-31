import { Controller } from '@hotwired/stimulus';

// 録音 → サーバーへ送信 → 返ってきた文字起こしを表示する

// Connects to data-controller="transcription"
export default class extends Controller {
  static targets = ['recordButton', 'stopButton', 'loadButton', 'status', 'transcript'];

  connect() {
    this.mediaRecorder = null;
    this.chunks = [];
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
    this.recordingTimeout = null;
    this.setIdleState();
  }

  async start(event) {
    event?.preventDefault();
    if (!navigator.mediaDevices?.getUserMedia) {
      return this.showError('お使いのブラウザは録音に対応していません。');
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });

      // Safari対応として 'audio/mp4' を追加
      const mimeTypes = ['audio/webm;codecs=opus', 'audio/mp4', 'audio/webm', 'audio/ogg'];
      const mimeType = mimeTypes.find(m => MediaRecorder.isTypeSupported(m)) || '';

      this.mediaRecorder = new MediaRecorder(stream, mimeType ? { mimeType } : undefined);
      this.chunks = [];

      this.mediaRecorder.ondataavailable = e => {
        if (e.data.size > 0) this.chunks.push(e.data);
      };

      this.mediaRecorder.onstop = () => this.handleStop();
      this.mediaRecorder.start();
      this.setRecordingState();

      // 30秒後に自動でストップメソッドを呼ぶ
      this.recordingTimeout = setTimeout(() => {
        this.stop();
        this.statusTarget.textContent = '30秒経過したため、録音を自動停止しました...';
      }, 30000);

    } catch (err) {
      this.showError(`マイクの利用を許可してください: ${err.message}`);
    }
  }

  stop(event) {
    event?.preventDefault();

    // 手動で停止した場合は、30秒タイマーをキャンセルする
    if (this.recordingTimeout) {
      clearTimeout(this.recordingTimeout);
      this.recordingTimeout = null;
    }

    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      this.mediaRecorder.stop();
      this.mediaRecorder.stream.getTracks().forEach(t => t.stop());
      this.setUploadingState();
    }
  }

  handleStop() {
    const mimeType = this.chunks[0]?.type || 'audio/webm';
    const blob = new Blob(this.chunks, { type: mimeType });
    // mp4の場合は拡張子をm4aに（Whisper等のAPIが認識しやすいため）
    const ext = mimeType.includes('mp4') ? 'm4a' : (mimeType.includes('ogg') ? 'ogg' : 'webm');
    const file = new File([blob], `recording-${Date.now()}.${ext}`, { type: blob.type });

    this.uploadFile(file);
    this.mediaRecorder = null;
  }

  // 音データを受け取って、transcriptコントローラのcreateアクション実行。ページのtranscript_idを持つ要素へテキスト挿入する。
  async uploadFile(file) {
    this.clearTranscript();
    this.statusTarget.textContent = 'UP中';
    this.disableControls(true);

    const form = new FormData();
    form.append('audio', file);

    try {
      const res = await fetch('/transcriptions', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          ...(this.csrfToken ? { 'X-CSRF-Token': this.csrfToken } : {}),
        },
        body: form,
      });

      if (!res.ok) throw new Error(`サーバーエラー: ${res.status}`);

      // -- transcriptコントローラのcreateアクションからtextデータを受ける --
      const data = await res.json();
      if (data.error) throw new Error(data.error);
      // transcript_idのvalueにテキスト挿入。
      document.querySelector('#transcript_id').value = data.text || '';
      this.statusTarget.textContent = '文字起こしが完了しました';
    } catch (err) {
      this.showError(`エラーが発生しました: ${err.message}`);
    } finally {
      this.setIdleState();
    }
  }

  // --- UI ヘルパー ---
  setRecordingState() {
    this.recordButtonTarget.disabled = true;
    this.recordButtonTarget.classList.add('hidden');

    this.stopButtonTarget.disabled = false;
    this.stopButtonTarget.classList.remove('hidden');

    this.statusTarget.textContent = '録音中...';
  }

  setUploadingState() {
    this.recordButtonTarget.disabled = true;
    this.stopButtonTarget.classList.add('hidden');

    this.stopButtonTarget.disabled = true;
    this.stopButtonTarget.classList.add('hidden');

    this.loadButtonTarget.classList.remove('hidden');
    this.statusTarget.textContent = 'UP中...';
  }

  setIdleState() {
    this.recordButtonTarget.disabled = false;
    this.recordButtonTarget.classList.remove('hidden');

    if (this.stopButtonTarget) this.stopButtonTarget.disabled = true;
    this.stopButtonTarget.classList.add('hidden');
    this.loadButtonTarget.classList.add('hidden');
    this.statusTarget.textContent = '準備完了';
  }

  disableControls(flag) {
    this.recordButtonTarget.disabled = flag;
    if (this.stopButtonTarget) this.stopButtonTarget.disabled = flag;
  }

  showError(message) {
    this.statusTarget.textContent = message;
    console.error(message);
  }

  clearTranscript() {
    if (this.transcriptTarget) this.transcriptTarget.textContent = '';
  }
}
