import { KeyboardSkinStyle } from '../common/KeyboardSkinStyle';

@Component
export struct FuncKey {
  @Prop label: ResourceStr = '';
  iconRes: Resource | undefined = undefined;
  @Prop weight: number = 1.5;
  @Prop highlighted: boolean = false; // shift锁定时变深
  keyIndex: number = -1;
  onPress: () => void = () => {};
  @State private pressed: boolean = false;
  @StorageLink('ime.keyFontScale') keyFontScale: number = 100;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';

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
            .backgroundColor(KeyboardSkinStyle.functionKeyBackground(this.skinPreset, this.skinKeyColor,
              this.highlighted, this.pressed, this.keyIndex))
            .opacity(KeyboardSkinStyle.keyColorOverlayOpacity(this.pressed || this.highlighted))
        }
        if (this.iconRes !== undefined) {
          Image(this.iconRes)
            .width(22)
            .height(22)
            .fillColor(KeyboardSkinStyle.keyMainTextColor(this.skinPreset, this.keyIndex))
        } else {
          Text(this.label)
            .fontSize(this.scaledFontSize(16))
            .fontWeight(FontWeight.Medium)
            .fontColor(KeyboardSkinStyle.keyMainTextColor(this.skinPreset, this.keyIndex))
        }
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
    }
    .layoutWeight(this.weight)
    .height('100%')
    .margin({ left: 3, right: 3 })
    .padding(0)
    .backgroundColor(KeyboardSkinStyle.functionKeyBackground(this.skinPreset, this.skinKeyColor,
      this.highlighted, this.pressed, this.keyIndex))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(14)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.functionKeyMaterial(this.skinPreset, this.highlighted, this.pressed,
      this.keyIndex, this.skinKeyColor))
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.pressed = true;
      } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      this.onPress();
    })
  }
}

/**
 * 蓝色主操作键（回车/搜索/发送）
 */
@Component
export struct EnterKey {
  @Prop label: ResourceStr = '↵';
  @Prop weight: number = 2.0;
  keyIndex: number = -1;
  onPress: () => void = () => {};
  @State private pressed: boolean = false;
  @StorageLink('ime.keyFontScale') keyFontScale: number = 100;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

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
            .backgroundColor(KeyboardSkinStyle.primaryBackground(this.skinPreset, this.pressed, this.keyIndex))
            .opacity(KeyboardSkinStyle.keyColorOverlayOpacity(this.pressed))
        }
        Text(this.label)
          .fontSize(this.scaledFontSize(16))
          .fontWeight(FontWeight.Bold)
          .fontColor(KeyboardSkinStyle.primaryTextColor(this.skinPreset, this.keyIndex))
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
    }
    .layoutWeight(this.weight)
    .height('100%')
    .margin({ left: 3, right: 3 })
    .padding(0)
    .backgroundColor(KeyboardSkinStyle.primaryBackground(this.skinPreset, this.pressed, this.keyIndex))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(14)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.primaryMaterial(this.skinPreset, this.pressed, this.keyIndex))
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.pressed = true;
      } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      this.onPress();
    })
  }
}
