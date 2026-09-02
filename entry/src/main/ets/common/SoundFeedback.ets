import { audio } from '@kit.AudioKit';
import { media } from '@kit.MediaKit';
import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'SoundFeedback';
const RAW_SOUND_PATH: string = 'key_click.wav';

export class SoundFeedback {
  private static soundPool: media.SoundPool | undefined = undefined;
  private static soundId: number = 0;
  private static ready: boolean = false;
  private static loading: boolean = false;

  public static init(resourceMgr: resourceManager.ResourceManager): void {
    if (SoundFeedback.ready || SoundFeedback.loading) {
      return;
    }
    SoundFeedback.loading = true;
    let rendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_GAME,
      rendererFlags: 0
    };
    media.createSoundPool(2, rendererInfo).then((pool: media.SoundPool) => {
      SoundFeedback.soundPool = pool;
      try {
        let fd: resourceManager.RawFileDescriptor = resourceMgr.getRawFdSync(RAW_SOUND_PATH);
        pool.load(fd.fd, fd.offset, fd.length).then((soundId: number) => {
          SoundFeedback.soundId = soundId;
          SoundFeedback.ready = true;
          SoundFeedback.loading = false;
          try {
            resourceMgr.closeRawFdSync(RAW_SOUND_PATH);
          } catch (e) {
            hilog.error(0x0000, TAG, 'close raw sound fd failed');
          }
        }).catch(() => {
          SoundFeedback.loading = false;
          hilog.error(0x0000, TAG, 'load sound failed');
        });
      } catch (e) {
        SoundFeedback.loading = false;
        hilog.error(0x0000, TAG, 'open raw sound failed');
      }
    }).catch(() => {
      SoundFeedback.loading = false;
      hilog.error(0x0000, TAG, 'create sound pool failed');
    });
  }

  public static play(enabled: boolean, volumePercent: number): void {
    if (!enabled || volumePercent <= 0 || !SoundFeedback.ready ||
      SoundFeedback.soundPool === undefined || SoundFeedback.soundId <= 0) {
      return;
    }
    let volume: number = Math.max(0, Math.min(1, volumePercent / 100));
    let params: media.PlayParameters = {
      loop: 0,
      leftVolume: volume,
      rightVolume: volume,
      priority: 1
    };
    SoundFeedback.soundPool.play(SoundFeedback.soundId, params).catch(() => {
      hilog.error(0x0000, TAG, 'play sound failed');
    });
  }
}
