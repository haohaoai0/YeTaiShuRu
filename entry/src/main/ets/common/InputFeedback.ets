import { vibrator } from '@kit.SensorServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'InputFeedback';

export class InputFeedback {
  public static triggerKey(strength: number): void {
    if (strength <= 0) {
      return;
    }
    let duration: number = Math.max(8, Math.min(35, Math.floor(strength / 3)));
    let effect: vibrator.VibrateTime = {
      type: 'time',
      duration: duration
    };
    let attribute: vibrator.VibrateAttribute = {
      usage: 'touch'
    };
    vibrator.startVibration(effect, attribute).catch(() => {
      hilog.error(0x0000, TAG, 'key vibration failed');
    });
  }
}
