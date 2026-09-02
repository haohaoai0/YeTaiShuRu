import { inputMethodEngine } from '@kit.IMEKit';
import { InputHandler } from '../InputMethodExtensionAbility/model/KeyboardController';
import { KeyboardMode } from '../model/KeyboardKeyData';
import { EnterKey, FuncKey } from './FuncKey';
import { SpaceKey } from './SpaceKey';

@Component
export struct EditKeyboard {
  @Consume keyboardMode: number;
  @StorageLink('subtypeId') subtypeId: string = 'EN';
  @StorageLink('ime.enterSend') enterSend: boolean = false;

  private enterLabel(): string {
    if (this.subtypeId === 'ZH') {
      if (this.enterSend) {
        return '发送';
      }
      return '搜索';
    }
    return 'Enter';
  }

  private moveLeft(): void {
    InputHandler.getInstance().moveCursor(inputMethodEngine.Direction.CURSOR_LEFT);
  }

  private moveRight(): void {
    InputHandler.getInstance().moveCursor(inputMethodEngine.Direction.CURSOR_RIGHT);
  }

  private moveUp(): void {
    InputHandler.getInstance().moveCursor(inputMethodEngine.Direction.CURSOR_UP);
  }

  private moveDown(): void {
    InputHandler.getInstance().moveCursor(inputMethodEngine.Direction.CURSOR_DOWN);
  }

  build() {
    Column() {
      Row() {
        FuncKey({
          label: 'ABC',
          weight: 1.3,
          onPress: () => {
            this.keyboardMode = KeyboardMode.LETTER;
          }
        })
        FuncKey({
          label: '⌫',
          weight: 1.3,
          onPress: () => InputHandler.getInstance().deleteSmart()
        })
        FuncKey({
          label: '⌦',
          weight: 1.3,
          onPress: () => InputHandler.getInstance().deleteBackward(1)
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 22, right: 22 })

      Row() {
        Blank().layoutWeight(1)
        FuncKey({
          label: '↑',
          weight: 1.2,
          onPress: () => this.moveUp()
        })
        Blank().layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 36, right: 36 })
      .margin({ top: 4 })

      Row() {
        FuncKey({
          label: '←',
          weight: 1.2,
          onPress: () => this.moveLeft()
        })
        FuncKey({
          label: '↓',
          weight: 1.2,
          onPress: () => this.moveDown()
        })
        FuncKey({
          label: '→',
          weight: 1.2,
          onPress: () => this.moveRight()
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 36, right: 36 })
      .margin({ top: 4 })

      Row() {
        FuncKey({
          label: '123',
          weight: 1.5,
          onPress: () => {
            this.keyboardMode = KeyboardMode.NUMBER;
          }
        })
        FuncKey({
          label: '.',
          weight: 1.0,
          onPress: () => InputHandler.getInstance().inputPunctuation('.')
        })
        SpaceKey({ weight: 4.0 })
        EnterKey({
          label: this.enterLabel(),
          weight: 2.0,
          onPress: () => InputHandler.getInstance().sendEnterKey()
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })
      .margin({ top: 4 })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 4, bottom: 12 })
  }
}
