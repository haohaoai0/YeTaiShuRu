import { InputHandler, keyboardController } from '../InputMethodExtensionAbility/model/KeyboardController';
import { LETTER_ROWS, KeyboardMode, ShiftState, KeyData } from '../model/KeyboardKeyData';
import { KeyItem } from './KeyItem';
import { FuncKey, EnterKey } from './FuncKey';
import { SpaceKey } from './SpaceKey';

@Component
export struct LetterKeyboard {
  @Consume @Watch('onShiftChange') shiftState: number;
  @Consume keyboardMode: number;
  @StorageLink('subtypeId') subtypeId: string = 'EN';
  @StorageLink('ime.enterSend') enterSend: boolean = false;
  @StorageLink('ime.swapLangNumber') swapLangNumber: boolean = false;

  private lastShiftClickTime: number = 0;

  onShiftChange(): void {
    // 子组件按 @Consume 自动跟随刷新
  }

  private onShiftClick(): void {
    let now: number = Date.now();
    if (now - this.lastShiftClickTime < 300) {
      // 双击 → 大写锁定
      this.shiftState = ShiftState.LOCK;
    } else {
      // 状态机：OFF → ONCE → LOCK → OFF
      if (this.shiftState === ShiftState.OFF) {
        this.shiftState = ShiftState.ONCE;
      } else if (this.shiftState === ShiftState.ONCE) {
        this.shiftState = ShiftState.LOCK;
      } else {
        this.shiftState = ShiftState.OFF;
      }
    }
    this.lastShiftClickTime = now;
  }

  private switchSubtype(): void {
    keyboardController.switchSubtype();
  }

  private languageLabel(): string {
    if (this.subtypeId === 'ZH') {
      return '中';
    }
    return '英';
  }

  private enterLabel(): string {
    if (this.subtypeId === 'ZH') {
      if (this.enterSend) {
        return '发送';
      }
      return '搜索';
    }
    return 'Enter';
  }

  build() {
    Column() {
      // 第一行：q w e r t y u i o p
      Row() {
        ForEach(LETTER_ROWS[0], (item: KeyData, index: number) => {
          KeyItem({ title: item.title, content: item.content, upperContent: item.upperContent, keyIndex: index })
        }, (item: KeyData) => item.content)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })

      // 第二行：a s d f g h j k l —— 比第一行内缩
      Row() {
        Blank().layoutWeight(0.5)
        ForEach(LETTER_ROWS[1], (item: KeyData, index: number) => {
          KeyItem({ title: item.title, content: item.content, upperContent: item.upperContent, keyIndex: index + 10 })
        }, (item: KeyData) => item.content)
        Blank().layoutWeight(0.5)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })
      .margin({ top: 4 })

      // 第三行：[shift] z x c v b n m [del]
      Row() {
        FuncKey({
          label: this.shiftState === ShiftState.LOCK ? '⇪' : '⇧',
          weight: 1.5,
          highlighted: this.shiftState !== ShiftState.OFF,
          keyIndex: 27,
          onPress: () => this.onShiftClick()
        })
        ForEach(LETTER_ROWS[2], (item: KeyData, index: number) => {
          KeyItem({ title: item.title, content: item.content, upperContent: item.upperContent, keyIndex: index + 19 })
        }, (item: KeyData) => item.content)
        FuncKey({
          label: '⌫',
          weight: 1.5,
          keyIndex: 28,
          onPress: () => InputHandler.getInstance().deleteSmart()
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })
      .margin({ top: 4 })

      // 第四行（底部）：123 / ,  / 空格 / 中英 / 搜索  —— 总权重 = 10
      Row() {
        if (this.swapLangNumber) {
          FuncKey({
            label: this.languageLabel(),
            weight: 1.5,
            keyIndex: 29,
            onPress: () => this.switchSubtype()
          })
        } else {
          FuncKey({
            label: '123',
            weight: 1.5,
            keyIndex: 29,
            onPress: () => { this.keyboardMode = KeyboardMode.NUMBER; }
          })
        }
        FuncKey({
          label: ',',
          weight: 1.0,
          keyIndex: 30,
          onPress: () => InputHandler.getInstance().inputPunctuation(',')
        })
        SpaceKey({ weight: 4.0, keyIndex: 31 })
        if (this.swapLangNumber) {
          FuncKey({
            label: '123',
            weight: 1.5,
            keyIndex: 32,
            onPress: () => { this.keyboardMode = KeyboardMode.NUMBER; }
          })
        } else {
          FuncKey({
            label: this.languageLabel(),
            weight: 1.5,
            keyIndex: 32,
            onPress: () => this.switchSubtype()
          })
        }
        EnterKey({
          label: this.enterLabel(),
          weight: 2.0,
          keyIndex: 33,
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
