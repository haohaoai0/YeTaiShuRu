import { InputHandler, keyboardController } from '../InputMethodExtensionAbility/model/KeyboardController';
import { KeyboardSkinStyle } from '../common/KeyboardSkinStyle';
import { NUMBER_ROWS, KeyboardMode } from '../model/KeyboardKeyData';
import { FuncKey, EnterKey } from './FuncKey';
import { SpaceKey } from './SpaceKey';

@Component
struct NumKey {
  char: string = '';
  keyIndex: number = 0;
  @State private pressed: boolean = false;
  @StorageLink('ime.keyPopup') keyPopupEnabled: boolean = true;
  @StorageLink('ime.keyFontScale') keyFontScale: number = 100;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';

  private getKeyBackground(): ResourceColor {
    return KeyboardSkinStyle.keyBackground(this.skinPreset, this.skinKeyColor, this.pressed, this.keyIndex);
  }

  private scaledFontSize(baseSize: number): number {
    return Math.round(baseSize * this.keyFontScale / 100);
  }

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Stack() {
        if (KeyboardSkinStyle.usesKeyColorOverlay(this.skinPreset)) {
          Blank()
            .width('100%')
            .height('100%')
            .backgroundColor(this.getKeyBackground())
            .opacity(KeyboardSkinStyle.keyColorOverlayOpacity(this.pressed))
        }
        Text(this.char)
          .fontSize(this.scaledFontSize(20))
          .fontWeight(FontWeight.Medium)
          .fontColor(KeyboardSkinStyle.keyMainTextColor(this.skinPreset, this.keyIndex))
        if (this.pressed && this.keyPopupEnabled) {
          Text(this.char)
            .fontSize(this.scaledFontSize(28))
            .fontWeight(FontWeight.Bold)
            .fontColor(KeyboardSkinStyle.keyMainTextColor(this.skinPreset, this.keyIndex))
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(KeyboardSkinStyle.keyBackground(this.skinPreset, this.skinKeyColor, true, this.keyIndex))
            .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
            .borderRadius(14)
            .translate({ y: -14 })
        }
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
    }
    .layoutWeight(1)
    .height('100%')
    .margin({ left: 3, right: 3 })
    .padding(0)
    .backgroundColor(this.getKeyBackground())
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(14)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.keyMaterial(this.skinPreset, this.pressed, this.keyIndex, this.skinKeyColor))
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.pressed = true;
      } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      InputHandler.getInstance().inputPunctuation(this.char);
    })
  }
}

@Component
export struct NumberKeyboard {
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

  private languageLabel(): string {
    if (this.subtypeId === 'ZH') {
      return '中';
    }
    return '英';
  }

  private switchSubtype(): void {
    keyboardController.switchSubtype();
  }

  build() {
    Column() {
      // 第1行
      Row() {
        ForEach(NUMBER_ROWS[0], (c: string, index: number) => {
          NumKey({ char: c, keyIndex: index })
        }, (c: string) => c)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })

      // 第2行
      Row() {
        ForEach(NUMBER_ROWS[1], (c: string, index: number) => {
          NumKey({ char: c, keyIndex: index + 10 })
        }, (c: string) => c)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })
      .margin({ top: 4 })

      // 第3行：[#+=] + 7个符号 + [⌫]
      Row() {
        FuncKey({
          label: '#+=',
          weight: 1.5,
          keyIndex: 30,
          onPress: () => { this.keyboardMode = KeyboardMode.SYMBOL; }
        })
        ForEach(NUMBER_ROWS[2], (c: string, index: number) => {
          NumKey({ char: c, keyIndex: index + 20 })
        }, (c: string) => c)
        FuncKey({
          label: '⌫',
          weight: 1.5,
          keyIndex: 31,
          onPress: () => InputHandler.getInstance().deleteSmart()
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })
      .margin({ top: 4 })

      // 第4行
      Row() {
        FuncKey({
          label: 'ABC',
          weight: 1.5,
          keyIndex: 32,
          onPress: () => { this.keyboardMode = KeyboardMode.LETTER; }
        })
        FuncKey({
          label: '.',
          weight: 1.0,
          keyIndex: 33,
          onPress: () => InputHandler.getInstance().inputPunctuation('.')
        })
        SpaceKey({ weight: 4.0, keyIndex: 34 })
        FuncKey({
          label: this.languageLabel(),
          weight: 1.5,
          keyIndex: 35,
          onPress: () => { this.switchSubtype(); }
        })
        EnterKey({
          label: this.enterLabel(),
          weight: 2.0,
          keyIndex: 36,
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
