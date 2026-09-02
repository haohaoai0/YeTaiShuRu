import { InputMethodExtensionAbility } from '@kit.IMEKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { keyboardController } from './model/KeyboardController';

const TAG: string = 'InputMethodService';

export default class InputMethodService extends InputMethodExtensionAbility {
  onCreate(want: Want): void {
    hilog.info(0x0000, TAG, 'onCreate, abilityName: %{public}s', want.abilityName ?? '');
    keyboardController.onCreate(this.context);
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'onDestroy');
    keyboardController.onDestroy();
  }
}
