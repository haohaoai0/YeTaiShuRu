import { AbilityStage } from '@kit.AbilityKit';

export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    console.info('MyInputMethod', 'AbilityStage onCreate');
  }
}
