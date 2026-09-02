import { InputHandler } from '../InputMethodExtensionAbility/model/KeyboardController';
import { KeyboardSkinStyle } from '../common/KeyboardSkinStyle';
import { ShiftState } from '../model/KeyboardKeyData';

@Component
export struct KeyItem {
  title: string = '';
  content: string = '';
  upperContent: string = '';
  keyIndex: number = 0;
  @Consume shiftState: number;
  @StorageLink('ime.numberRow') numberRowEnabled: boolean = true;
  @StorageLink('ime.upperCase') upperCaseEnabled: boolean = false;
  @StorageLink('ime.swipeInput') swipeInputEnabled: boolean = false;
  @StorageLink('ime.keyPopup') keyPopupEnabled: boolean = true;
  @StorageLink('ime.keyFontScale') keyFontScale: number = 100;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';
  @StorageLink('subtypeId') subtypeId: string = 'EN';
  @State private pressed: boolean = false;
  private touchStartY: number = 0;
  private swipeCommitted: boolean = false;

  private displayChar(): string {
    if (this.shiftState !== ShiftState.OFF || (this.upperCaseEnabled && this.subtypeId === 'EN')) {
      return this.upperContent;
    }
    return this.content;
  }

  private handleTouch(e: TouchEvent): void {
    if (e.type === TouchType.Down) {
      this.pressed = true;
      this.swipeCommitted = false;
      if (e.touches.length > 0) {
        this.touchStartY = e.touches[0].windowY;
      }
    } else if (e.type === TouchType.Up) {
      this.pressed = false;
      if (e.touches.length > 0) {
        let deltaY: number = this.touchStartY - e.touches[0].windowY;
        if (this.swipeInputEnabled && this.numberRowEnabled && this.title.length > 0 && deltaY >= 18) {
          this.swipeCommitted = true;
          InputHandler.getInstance().inputPunctuation(this.title);
        }
      }
    } else if (e.type === TouchType.Cancel) {
      this.pressed = false;
      this.swipeCommitted = false;
    }
  }

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
        Column() {
          if (this.title.length > 0 && this.numberRowEnabled) {
            Text(this.title)
              .fontSize(this.scaledFontSize(9))
              .fontColor(KeyboardSkinStyle.keyHintTextColor(this.skinPreset, this.keyIndex))
              .height(12)
          } else {
            Blank()
              .height(12)
          }
          Text(this.displayChar())
            .fontSize(this.scaledFontSize(22))
            .fontWeight(FontWeight.Medium)
            .fontColor(KeyboardSkinStyle.keyMainTextColor(this.skinPreset, this.keyIndex))
            .height(28)
          Blank()
            .height(4)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .height('100%')
        if (this.pressed && this.keyPopupEnabled) {
          Text(this.displayChar())
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
      this.handleTouch(e);
    })
    .onClick(() => {
      if (this.swipeCommitted) {
        this.swipeCommitted = false;
        return;
      }
      InputHandler.getInstance().inputLetter(this.displayChar());
      if (this.shiftState === ShiftState.ONCE) {
        this.shiftState = ShiftState.OFF;
      }
    })
  }
}
