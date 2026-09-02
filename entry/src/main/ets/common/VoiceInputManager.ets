import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { speechRecognizer } from '@kit.CoreSpeechKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VoiceInputManager';
const AUDIO_FRAME_BYTES: number = 1280;
const AUDIO_SAMPLE_RATE: number = 16000;

export enum VoiceInputState {
  IDLE = 0,
  STARTING = 1,
  LISTENING = 2,
  PROCESSING = 3,
  ERROR = 4
}

export class VoiceInputManager {
  private engine: speechRecognizer.SpeechRecognitionEngine | undefined = undefined;
  private capturer: audio.AudioCapturer | undefined = undefined;
  private sessionId: string = '';
  private engineLanguage: string = '';
  private pendingAudio: Uint8Array = new Uint8Array(0);
  private capturing: boolean = false;
  private stopRequested: boolean = false;
  private resultCallback: (text: string) => void = (text: string): void => {};
  private readDataCallback: Callback<ArrayBuffer> = (buffer: ArrayBuffer): void => {
    this.writeAudioBuffer(buffer);
  };

  public setResultCallback(callback: (text: string) => void): void {
    this.resultCallback = callback;
  }

  public initialize(): void {
    this.publishState(VoiceInputState.IDLE);
    this.publishPreview('');
  }

  public async start(language: string): Promise<boolean> {
    if (this.capturing) {
      return true;
    }
    this.stopRequested = false;
    this.publishState(VoiceInputState.STARTING);
    this.publishPreview('');
    try {
      await this.prepareEngine(language);
      if (this.engine === undefined) {
        this.publishState(VoiceInputState.ERROR);
        return false;
      }
      this.sessionId = this.createSessionId();
      let audioInfo: speechRecognizer.AudioInfo = {
        audioType: 'pcm',
        sampleRate: AUDIO_SAMPLE_RATE,
        soundChannel: 1,
        sampleBit: 16
      };
      let startParams: speechRecognizer.StartParams = {
        sessionId: this.sessionId,
        audioInfo: audioInfo
      };
      this.engine.startListening(startParams);
      this.capturer = await audio.createAudioCapturer(this.createCapturerOptions());
      this.capturer.on('readData', this.readDataCallback);
      await this.capturer.start();
      this.capturing = true;
      this.publishState(VoiceInputState.LISTENING);
      if (this.stopRequested) {
        this.stop();
      }
      return true;
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'start voice input failed: %{public}d %{public}s', err.code, err.message);
      this.cancelRecognitionSession();
      await this.releaseCapturer();
      this.publishState(VoiceInputState.ERROR);
      return false;
    }
  }

  public stop(): void {
    this.stopRequested = true;
    if (!this.capturing) {
      return;
    }
    this.finishRecognition().catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'finish voice input failed: %{public}d %{public}s', err.code, err.message);
      this.publishState(VoiceInputState.ERROR);
    });
  }

  public cancel(): void {
    this.stopRequested = true;
    this.cancelRecognitionSession();
    this.releaseCapturer().catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'release voice capturer failed: %{public}d %{public}s', err.code, err.message);
    });
    this.sessionId = '';
    this.pendingAudio = new Uint8Array(0);
    this.capturing = false;
    this.publishPreview('');
    this.publishState(VoiceInputState.IDLE);
  }

  public shutdown(): void {
    this.cancel();
    if (this.engine !== undefined) {
      try {
        this.engine.shutdown();
      } catch (e) {
        let err: BusinessError = e as BusinessError;
        hilog.error(0x0000, TAG, 'shutdown speech engine failed: %{public}d %{public}s', err.code, err.message);
      }
    }
    this.engine = undefined;
    this.engineLanguage = '';
  }

  public handleStart(sessionId: string): void {
    if (sessionId === this.sessionId) {
      this.publishState(VoiceInputState.LISTENING);
    }
  }

  public handleResult(sessionId: string, result: speechRecognizer.SpeechRecognitionResult): void {
    if (sessionId !== this.sessionId || result.result.length === 0) {
      return;
    }
    this.publishPreview(result.result);
    if (result.isFinal) {
      this.resultCallback(result.result);
      this.publishPreview('');
    }
  }

  public handleComplete(sessionId: string): void {
    if (sessionId !== this.sessionId) {
      return;
    }
    this.sessionId = '';
    this.pendingAudio = new Uint8Array(0);
    this.capturing = false;
    this.publishPreview('');
    this.publishState(VoiceInputState.IDLE);
  }

  public handleError(sessionId: string, errorCode: number, errorMessage: string): void {
    if (sessionId.length > 0 && this.sessionId.length > 0 && sessionId !== this.sessionId) {
      return;
    }
    hilog.error(0x0000, TAG, 'speech recognition error: %{public}d %{public}s', errorCode, errorMessage);
    this.sessionId = '';
    this.pendingAudio = new Uint8Array(0);
    this.capturing = false;
    this.releaseCapturer().catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'release capturer after recognition error failed: %{public}d %{public}s',
        err.code, err.message);
    });
    this.publishPreview('');
    this.publishState(VoiceInputState.ERROR);
  }

  private async prepareEngine(language: string): Promise<void> {
    if (this.engine !== undefined && this.engineLanguage === language) {
      return;
    }
    if (this.engine !== undefined) {
      this.engine.shutdown();
      this.engine = undefined;
    }
    let createParams: speechRecognizer.CreateEngineParams = {
      language: language,
      online: 1
    };
    this.engine = await speechRecognizer.createEngine(createParams);
    this.engineLanguage = language;
    this.engine.setListener(new VoiceRecognitionListener(this));
  }

  private createCapturerOptions(): audio.AudioCapturerOptions {
    let streamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    };
    let capturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_VOICE_RECOGNITION,
      capturerFlags: 0
    };
    let options: audio.AudioCapturerOptions = {
      streamInfo: streamInfo,
      capturerInfo: capturerInfo
    };
    return options;
  }

  private createSessionId(): string {
    return 'liquid_ime_' + Date.now().toString() + '_' + Math.floor(Math.random() * 100000).toString();
  }

  private writeAudioBuffer(buffer: ArrayBuffer): void {
    if (!this.capturing || this.engine === undefined || this.sessionId.length === 0) {
      return;
    }
    let incoming: Uint8Array = new Uint8Array(buffer);
    let combined: Uint8Array = new Uint8Array(this.pendingAudio.length + incoming.length);
    let i: number = 0;
    for (i = 0; i < this.pendingAudio.length; i++) {
      combined[i] = this.pendingAudio[i];
    }
    for (i = 0; i < incoming.length; i++) {
      combined[this.pendingAudio.length + i] = incoming[i];
    }
    let offset: number = 0;
    while (combined.length - offset >= AUDIO_FRAME_BYTES) {
      let frame: Uint8Array = new Uint8Array(AUDIO_FRAME_BYTES);
      for (i = 0; i < AUDIO_FRAME_BYTES; i++) {
        frame[i] = combined[offset + i];
      }
      try {
        this.engine.writeAudio(this.sessionId, frame);
      } catch (e) {
        let err: BusinessError = e as BusinessError;
        hilog.error(0x0000, TAG, 'write speech audio failed: %{public}d %{public}s', err.code, err.message);
        this.publishState(VoiceInputState.ERROR);
        return;
      }
      offset = offset + AUDIO_FRAME_BYTES;
    }
    let remaining: number = combined.length - offset;
    this.pendingAudio = new Uint8Array(remaining);
    for (i = 0; i < remaining; i++) {
      this.pendingAudio[i] = combined[offset + i];
    }
  }

  private async finishRecognition(): Promise<void> {
    this.capturing = false;
    await this.releaseCapturer();
    if (this.engine !== undefined && this.sessionId.length > 0) {
      this.engine.finish(this.sessionId);
      this.publishState(VoiceInputState.PROCESSING);
    } else {
      this.publishState(VoiceInputState.IDLE);
    }
  }

  private cancelRecognitionSession(): void {
    if (this.engine === undefined || this.sessionId.length === 0) {
      return;
    }
    try {
      this.engine.cancel(this.sessionId);
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'cancel speech recognition failed: %{public}d %{public}s', err.code, err.message);
    }
  }

  private async releaseCapturer(): Promise<void> {
    let current: audio.AudioCapturer | undefined = this.capturer;
    this.capturer = undefined;
    if (current === undefined) {
      return;
    }
    try {
      current.off('readData', this.readDataCallback);
      if (current.state === audio.AudioState.STATE_RUNNING || current.state === audio.AudioState.STATE_PAUSED) {
        await current.stop();
      }
      if (current.state !== audio.AudioState.STATE_RELEASED && current.state !== audio.AudioState.STATE_NEW) {
        await current.release();
      }
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'release audio capturer failed: %{public}d %{public}s', err.code, err.message);
    }
  }

  private publishState(state: number): void {
    AppStorage.setOrCreate('ime.voiceInputState', state);
  }

  private publishPreview(value: string): void {
    AppStorage.setOrCreate('ime.voiceInputPreview', value);
  }
}

class VoiceRecognitionListener implements speechRecognizer.RecognitionListener {
  private manager: VoiceInputManager;

  constructor(manager: VoiceInputManager) {
    this.manager = manager;
  }

  onStart(sessionId: string, eventMessage: string): void {
    this.manager.handleStart(sessionId);
  }

  onEvent(sessionId: string, eventCode: number, eventMessage: string): void {
  }

  onResult(sessionId: string, result: speechRecognizer.SpeechRecognitionResult): void {
    this.manager.handleResult(sessionId, result);
  }

  onComplete(sessionId: string, eventMessage: string): void {
    this.manager.handleComplete(sessionId);
  }

  onError(sessionId: string, errorCode: number, errorMessage: string): void {
    this.manager.handleError(sessionId, errorCode, errorMessage);
  }
}

export const voiceInputManager: VoiceInputManager = new VoiceInputManager();
