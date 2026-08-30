import { Controller } from '@hotwired/stimulus';

// 録音 → サーバーへ送信 → 返ってきた文字起こしを表示する

// MediaRecorder が使えればそちらを利用し、使えない（または希望する mimeType がサポートされない）場合は
// WebAudio + ScriptProcessor を使って WAV を作成するフォールバックを行います（Safari 対応）

// Connects to data-controller="transcription"
export default class extends Controller {
  static targets = ['recordButton', 'stopButton', 'status', 'transcript'];

  connect() {
    this.mediaRecorder = null;
    this.chunks = [];
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
    this.audioContext = null;
    this.recorderNode = null;
    this.recordingBuffers = [];
    this.sampleRate = 44100;
    this.setIdleState();
  }

  async start(event) {
    event?.preventDefault();
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.showError('お使いのブラウザは録音に対応していません。');
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });

      // 1) まず MediaRecorder を試す（推奨）
      if (window.MediaRecorder) {
        const preferred = [
          'audio/webm;codecs=opus',
          'audio/ogg;codecs=opus',
          'audio/webm',
          'audio/ogg',
        ];

        let selectedMime = null;
        for (const m of preferred) {
          if (MediaRecorder.isTypeSupported && MediaRecorder.isTypeSupported(m)) {
            selectedMime = m;
            break;
          }
        }

        try {
          // もし selectedMime が null でも MediaRecorder のデフォルトで作成してみる
          this.initMediaRecorder(stream, selectedMime ? { mimeType: selectedMime } : undefined);
          this.setRecordingState();
          return;
        } catch (err) {
          // MediaRecorder が失敗したらフォールバックへ
          console.warn('MediaRecorder 初期化失敗, フォールバックへ:', err);
        }
      }

      // 2) MediaRecorder が無い / 使えない場合は WebAudio -> WAV フォールバック
      await this.initRecorderFallback(stream);
      this.setRecordingState();
    } catch (err) {
      this.showError(`マイクの利用を許可してください: ${ err.message}`);
    }
  }

  stop(event) {
    event?.preventDefault();
    // MediaRecorder パス
    if (this.mediaRecorder) {
      // 停止すると 'stop' イベントで uploadFile が呼ばれます
      try {
        this.mediaRecorder.stop();
      } catch (e) {
        console.warn('mediaRecorder.stop() 失敗:', e);
      }
      // ストリームを停止
      this.mediaRecorder.stream?.getTracks().forEach(t => t.stop());
      this.setUploadingState();
      return;
    }

    // フォールバック（WebAudio）パス
    if (this.recorderNode && this.audioContext) {
      // 停止してバッファをエクスポート
      this.stopRecorderFallback();
      this.setUploadingState();
      return;
    }
  }

  // --- MediaRecorder initialisation ---
  initMediaRecorder(stream, options) {
    this.chunks = [];
    this.mediaRecorder = new MediaRecorder(stream, options);

    this.mediaRecorder.addEventListener('dataavailable', e => {
      if (e.data && e.data.size > 0) this.chunks.push(e.data);
    });

    this.mediaRecorder.addEventListener('stop', () => {
      try {
        const blob = new Blob(this.chunks, { type: this.chunks[0]?.type || 'application/octet-stream' });
        const filename = `recording-${Date.now()}.${this.guessExtension(blob.type)}`;
        const file = new File([blob], filename, { type: blob.type });
        this.uploadFile(file);
      } catch (e) {
        this.showError(`録音の処理中にエラーが発生しました: ${ e.message}`);
      } finally {
        this.mediaRecorder = null;
        this.chunks = [];
      }
    });

    this.mediaRecorder.start();
  }

  guessExtension(mime) {
    if (!mime) return 'dat';
    if (mime.includes('webm')) return 'webm';
    if (mime.includes('ogg')) return 'ogg';
    if (mime.includes('wav')) return 'wav';
    if (mime.includes('mpeg') || mime.includes('mp3')) return 'mp3';
    return 'dat';
  }

  // --- WebAudio (フォールバック) initialisation ---
  async initRecorderFallback(stream) {
    // Safari は AudioContext 名が window.webkitAudioContext の場合がある
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) throw new Error('このブラウザは WebAudio をサポートしていません。');

    this.audioContext = new AudioCtx();
    // iOS Safari の場合、AudioContext はユーザー操作で resume する必要があることがある
    if (this.audioContext.state === 'suspended' && typeof this.audioContext.resume === 'function') {
      await this.audioContext.resume().catch(() => {});
    }

    this.sampleRate = this.audioContext.sampleRate || 44100;
    const source = this.audioContext.createMediaStreamSource(stream);

    // ScriptProcessorNode は非推奨だが、互換性のためまだ使う（AudioWorklet は複雑）
    const bufferSize = 4096;
    const inputChannels = 1;
    const outputChannels = 1;
    const recorderNode = (this.audioContext.createScriptProcessor ||
                          this.audioContext.createScriptProcessor).call(this.audioContext, bufferSize, inputChannels, outputChannels);

    this.recordingBuffers = [];
    recorderNode.onaudioprocess = e => {
      const inputBuffer = e.inputBuffer.getChannelData(0);
      // copy
      this.recordingBuffers.push(new Float32Array(inputBuffer));
    };

    source.connect(recorderNode);
    recorderNode.connect(this.audioContext.destination); // 出力に接続しないと iOS で動かないケースがある

    this.recorderNode = recorderNode;
    this._fallbackStream = stream;
  }

  stopRecorderFallback() {
    try {
      // disconnect nodes
      this.recorderNode.disconnect();
      this.audioContext.close().catch(() => {});
      // stop tracks
      this._fallbackStream?.getTracks().forEach(t => t.stop());
    } catch (e) {
      console.warn('フォールバック停止でエラー:', e);
    }

    // WAV にエンコード
    const wavBlob = this.encodeWAV(this.recordingBuffers, this.sampleRate);
    const filename = `recording-${Date.now()}.wav`;
    const file = new File([wavBlob], filename, { type: 'audio/wav' });

    // reset
    this.recorderNode = null;
    this.audioContext = null;
    this.recordingBuffers = [];

    this.uploadFile(file);
  }

  // --- WAV エンコーダ（モノラル） ---
  encodeWAV(buffers, sampleRate) {
    // buffers: Array<Float32Array>
    const merged = this.mergeBuffers(buffers);
    const interleaved = this.floatTo16BitPCM(merged);
    const buffer = new ArrayBuffer(44 + interleaved.length * 2);
    const view = new DataView(buffer);

    /* RIFF identifier */
    this.writeString(view, 0, 'RIFF');
    /* file length */
    view.setUint32(4, 36 + interleaved.length * 2, true);
    /* RIFF type */
    this.writeString(view, 8, 'WAVE');
    /* format chunk identifier */
    this.writeString(view, 12, 'fmt ');
    /* format chunk length */
    view.setUint32(16, 16, true);
    /* sample format (raw) */
    view.setUint16(20, 1, true);
    /* channel count */
    view.setUint16(22, 1, true);
    /* sample rate */
    view.setUint32(24, sampleRate, true);
    /* byte rate (sampleRate * blockAlign) */
    view.setUint32(28, sampleRate * 2, true);
    /* block align (channel count * bytesPerSample) */
    view.setUint16(32, 2, true);
    /* bits per sample */
    view.setUint16(34, 16, true);
    /* data chunk identifier */
    this.writeString(view, 36, 'data');
    /* data chunk length */
    view.setUint32(40, interleaved.length * 2, true);

    // PCM samples
    let offset = 44;
    for (let i = 0; i < interleaved.length; i++, offset += 2) {
      view.setInt16(offset, interleaved[i], true);
    }

    return new Blob([view], { type: 'audio/wav' });
  }

  mergeBuffers(buffers) {
    let length = 0;
    for (let i = 0; i < buffers.length; i++) length += buffers[i].length;
    const result = new Float32Array(length);
    let offset = 0;
    for (let i = 0; i < buffers.length; i++) {
      result.set(buffers[i], offset);
      offset += buffers[i].length;
    }
    return result;
  }

  floatTo16BitPCM(float32Array) {
    const l = float32Array.length;
    const result = new Int16Array(l);
    for (let i = 0; i < l; i++) {
      const s = Math.max(-1, Math.min(1, float32Array[i]));
      result[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
    }
    return result;
  }

  writeString(view, offset, string) {
    for (let i = 0; i < string.length; i++) {
      view.setUint8(offset + i, string.charCodeAt(i));
    }
  }

  // --- Upload ---
  async uploadFile(file) {
    this.clearTranscript();
    this.statusTarget.textContent = 'アップロード中...';
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
        credentials: 'same-origin',
      });

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        throw new Error(`サーバーエラー: ${res.status} ${errText}`);
      }

      const data = await res.json().catch(() => ({}));
      if (data.error) throw new Error(data.error);

      this.transcriptTarget.textContent = data.text || '';
      this.statusTarget.textContent = '文字起こしが完了しました';

    } catch (err) {
      this.showError(`アップロード/文字起こしでエラーが発生しました: ${ err.message}`);
    } finally {
      this.disableControls(false);
      this.setIdleState();
    }
  }

  // --- UI ヘルパー ---
  setRecordingState() {
    this.recordButtonTarget.disabled = true;
    this.stopButtonTarget.disabled = false;
    this.statusTarget.textContent = '録音中...';
  }

  setUploadingState() {
    this.recordButtonTarget.disabled = true;
    this.stopButtonTarget.disabled = true;
    this.statusTarget.textContent = 'アップロード中...';
  }

  setIdleState() {
    this.recordButtonTarget.disabled = false;
    if (this.stopButtonTarget) this.stopButtonTarget.disabled = true;
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
