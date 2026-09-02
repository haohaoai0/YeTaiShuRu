import { InputHandler, keyboardController } from '../InputMethodExtensionAbility/model/KeyboardController';
import { KeyboardSkinStyle } from '../common/KeyboardSkinStyle';
import { KeyboardMode, T9KeyData, T9_ROWS } from '../model/KeyboardKeyData';
import { FuncKey, EnterKey } from './FuncKey';
import { SpaceKey } from './SpaceKey';

@Component
struct T9Key {
  item: T9KeyData = new T9KeyData('', '', '');
  keyIndex: number = 0;
  @State private pressed: boolean = false;
  @StorageLink('ime.keyPopup') keyPopupEnabled: boolean = true;
  @StorageLink('ime.keyFontScale') keyFontScale: number = 100;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';

  private pressKey(): void {
    if (this.item.digit === '1') {
      InputHandler.getInstance().inputPunctuation('，');
      return;
    }
    InputHandler.getInstance().inputT9Digit(this.item.digit);
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
            .backgroundColor(KeyboardSkinStyle.keyBackground(this.skinPreset, this.skinKeyColor, this.pressed,
              this.keyIndex))
            .opacity(KeyboardSkinStyle.keyColorOverlayOpacity(this.pressed))
        }
        Column() {
          Text(this.item.digit)
            .fontSize(this.scaledFontSize(24))
            .fontWeight(FontWeight.Bold)
            .fontColor(KeyboardSkinStyle.keyMainTextColor(this.skinPreset, this.keyIndex))
            .height(28)
          Text(this.item.letters.length > 0 ? this.item.letters : this.item.hint)
            .fontSize(this.scaledFontSize(10))
            .fontColor(KeyboardSkinStyle.keyHintTextColor(this.skinPreset, this.keyIndex))
            .maxLines(1)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .height('100%')
        if (this.pressed && this.keyPopupEnabled) {
          Text(this.item.digit)
            .fontSize(this.scaledFontSize(30))
            .fontWeight(FontWeight.Bold)
            .fontColor(KeyboardSkinStyle.keyMainTextColor(this.skinPreset, this.keyIndex))
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(KeyboardSkinStyle.keyBackground(this.skinPreset, this.skinKeyColor, true, this.keyIndex))
            .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
            .borderRadius(14)
            .translate({ y: -14 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .layoutWeight(1)
    .height('100%')
    .margin({ left: 4, right: 4 })
    .padding(0)
    .backgroundColor(KeyboardSkinStyle.keyBackground(this.skinPreset, this.skinKeyColor, this.pressed, this.keyIndex))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(18)
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
      this.pressKey();
    })
  }
}

@Component
export struct T9Keyboard {
  @Consume keyboardMode: number;
  @StorageLink('subtypeId') subtypeId: string = 'ZH';
  @StorageLink('ime.enterSend') enterSend: boolean = false;

  private switchSubtype(): void {
    keyboardController.switchSubtype();
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

  private languageLabel(): string {
    if (this.subtypeId === 'ZH') {
      return '中';
    }
    return '英';
  }

  build() {
    Column() {
      Row() {
        ForEach(T9_ROWS[0], (item: T9KeyData, index: number) => {
          T9Key({ item: item, keyIndex: index })
        }, (item: T9KeyData) => item.digit)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 6, right: 6 })

      Row() {
        ForEach(T9_ROWS[1], (item: T9KeyData, index: number) => {
          T9Key({ item: item, keyIndex: index + 3 })
        }, (item: T9KeyData) => item.digit)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 6, right: 6 })
      .margin({ top: 4 })

      Row() {
        ForEach(T9_ROWS[2], (item: T9KeyData, index: number) => {
          T9Key({ item: item, keyIndex: index + 6 })
        }, (item: T9KeyData) => item.digit)
        FuncKey({
          label: '⌫',
          weight: 1.0,
          keyIndex: 9,
          onPress: () => InputHandler.getInstance().deleteSmart()
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 6, right: 6 })
      .margin({ top: 4 })

      Row() {
        FuncKey({
          label: '123',
          weight: 1.2,
          keyIndex: 10,
          onPress: () => { this.keyboardMode = KeyboardMode.NUMBER; }
        })
        FuncKey({
          label: '，',
          weight: 0.9,
          keyIndex: 11,
          onPress: () => InputHandler.getInstance().inputPunctuation('，')
        })
        SpaceKey({ weight: 3.1, keyIndex: 12 })
        FuncKey({
          label: this.languageLabel(),
          weight: 1.4,
          keyIndex: 13,
          onPress: () => this.switchSubtype()
        })
        EnterKey({
          label: this.enterLabel(),
          weight: 1.8,
          keyIndex: 14,
          onPress: () => InputHandler.getInstance().sendEnterKey()
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 6, right: 6 })
      .margin({ top: 4 })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 4, bottom: 12 })
  }
}
