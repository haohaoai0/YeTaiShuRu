import { inputMethod } from '@kit.IMEKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'InputMethodStatus';
const LIQUID_IME_BUNDLE_NAME: string = 'com.my.liquidime';
const LIQUID_IME_LABEL_ZH: string = '液态输入法';
const LIQUID_IME_LABEL_EN: string = 'Liquid IME';

export class InputMethodStatus {
  public static isLiquidImeCurrent(): boolean {
    try {
      let current: inputMethod.InputMethodProperty = inputMethod.getCurrentInputMethod();
      return InputMethodStatus.matchesLiquidIme(current);
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'get current input method failed: %{public}d %{public}s', err.code, err.message);
    }
    return false;
  }

  private static matchesLiquidIme(value: inputMethod.InputMethodProperty): boolean {
    if (value.name === LIQUID_IME_BUNDLE_NAME) {
      return true;
    }
    if (value.id.indexOf(LIQUID_IME_BUNDLE_NAME) >= 0) {
      return true;
    }
    if (value.label !== undefined) {
      let label: string = value.label;
      if (label === LIQUID_IME_LABEL_ZH || label === LIQUID_IME_LABEL_EN) {
        return true;
      }
    }
    return false;
  }
}
