import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { inputMethodEngine } from '@kit.IMEKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { TopBar } from '../../components/TopBar';
import { LetterKeyboard } from '../../components/LetterKeyboard';
import { NumberKeyboard } from '../../components/NumberKeyboard';
import { SymbolKeyboard } from '../../components/SymbolKeyboard';
import { T9Keyboard } from '../../components/T9Keyboard';
import { EditKeyboard } from '../../components/EditKeyboard';
import { ClipboardKeyboard } from '../../components/ClipboardKeyboard';
import { EmojiKeyboard } from '../../components/EmojiKeyboard';
import { KeyboardSkinStyle } from '../../common/KeyboardSkinStyle';
import {
  KeyboardDockMode,
  KeyboardLayoutMode,
  KeyboardSkinBackgroundMode,
  KeyboardSkinImageAreaMode,
  KeyboardSkinPresetMode,
  SettingsStore
} from '../../model/ImeSettings';
import {
  ROUTE_HELP,
  ROUTE_KEY_EFFECT,
  ROUTE_KEYBOARD_MANAGE,
  ROUTE_DICTIONARY,
  ROUTE_SETTINGS_HOME
} from '../../model/SettingsLaunch';
import { KeyboardMode, ShiftState } from '../../model/KeyboardKeyData';
import { InputHandler, keyboardController } from '../model/KeyboardController';
import { SystemSymbolIcon } from '../../components/SystemSymbolIcon';
import { pinyinEngine } from '../../model/PinyinEngine';

const TAG: string = 'KeyboardPanel';
const KEYBOARD_PANEL_CORNER_RADIUS: number = 18;

@Component
struct PanelSettingCard {
  title: ResourceStr = '';
  symbol: Resource = $r('sys.symbol.keyboard');
  @Prop active: boolean = false;
  @Prop itemEnabled: boolean = true;
  onPress: () => void = () => {};
  @StorageLink('ime.skinPreset') skinPreset: number = 0;
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Column() {
        SystemSymbolIcon({
          symbol: this.symbol,
          color: this.active ? KeyboardSkinStyle.primaryBackground(this.skinPreset, false) :
            KeyboardSkinStyle.keyTextColor(this.skinPreset),
          iconSize: 26
        })

        Text(this.title)
          .fontSize(13)
          .fontWeight(this.active ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.active ? KeyboardSkinStyle.primaryBackground(this.skinPreset, false) :
            KeyboardSkinStyle.mutedTextColor(this.skinPreset))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .height(74)
    .layoutWeight(1)
    .padding({ left: 6, right: 6 })
    .margin({ left: 4, right: 4, top: 6 })
    .backgroundColor(KeyboardSkinStyle.cardBackground(this.skinPreset))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.cardMaterial(this.skinPreset))
    .enabled(this.itemEnabled)
    .opacity(this.itemEnabled ? 1 : 0.42)
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct PanelPageDot {
  @Prop active: boolean = false;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  build() {
    Blank()
      .width(this.active ? 22 : 8)
      .height(8)
      .backgroundColor(this.active ? KeyboardSkinStyle.primaryBackground(this.skinPreset, false) :
        KeyboardSkinStyle.chipBackground(this.skinPreset, false))
      .borderRadius(4)
      .clip(true)
      .systemMaterial(this.active ? KeyboardSkinStyle.primaryMaterial(this.skinPreset, false) :
        KeyboardSkinStyle.chipMaterial(this.skinPreset, false))
      .margin({ left: 5, right: 5 })
  }
}

@Component
struct PanelHeightSlider {
  @Prop @Watch('onValueChange') value: number = 32;
  min: number = 24;
  max: number = 42;
  onChange: (value: number) => void = (value: number) => {};
  @State private currentValue: number = 32;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  aboutToAppear(): void {
    this.currentValue = this.value;
  }

  onValueChange(): void {
    this.currentValue = this.value;
  }

  build() {
    Row() {
      Text($r('app.string.keyboard_height'))
        .width(72)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Slider({ value: this.currentValue, min: this.min, max: this.max, step: 1 })
        .layoutWeight(1)
        .height(26)
        .blockColor($r('app.color.slider_block'))
        .selectedColor($r('app.color.material_primary'))
        .trackColor($r('app.color.slider_track'))
        .margin({ left: 8, right: 8 })
        .onChange((value: number, mode: SliderChangeMode) => {
          let roundedValue: number = Math.round(value);
          this.currentValue = roundedValue;
          this.onChange(roundedValue);
        })
      Text(this.currentValue.toString() + '%')
        .width(36)
        .fontSize(12)
        .fontColor(KeyboardSkinStyle.mutedTextColor(this.skinPreset))
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .height(42)
    .padding({ left: 12, right: 12 })
    .margin({ left: 4, right: 4, top: 4 })
    .backgroundColor(KeyboardSkinStyle.cardBackground(this.skinPreset))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(16)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.cardMaterial(this.skinPreset))
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct SkinPresetButton {
  title: ResourceStr = '';
  backgroundColorValue: string = '#FFF1F4F9';
  keyColorValue: string = '#F2FFFFFF';
  @Prop selected: boolean = false;
  onPress: () => void = () => {};
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Column() {
        Stack() {
          Text('')
            .width('100%')
            .height('100%')
            .backgroundColor(this.backgroundColorValue)
          Row() {
            Blank()
              .layoutWeight(1)
              .height(18)
              .borderRadius(8)
              .backgroundColor(this.keyColorValue)
            Blank()
              .layoutWeight(1)
              .height(18)
              .borderRadius(8)
              .backgroundColor(this.keyColorValue)
              .margin({ left: 5 })
            Blank()
              .layoutWeight(1)
              .height(18)
              .borderRadius(8)
              .backgroundColor(this.keyColorValue)
              .margin({ left: 5 })
          }
          .width('82%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(44)
        .borderRadius(14)
        .clip(true)

        Text(this.title)
          .fontSize(12)
          .fontWeight(this.selected ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .height(78)
    .layoutWeight(1)
    .padding(7)
    .margin({ left: 4, right: 4, top: 6 })
    .backgroundColor(this.selected ? KeyboardSkinStyle.chipBackground(this.skinPreset, true) :
      KeyboardSkinStyle.cardBackground(this.skinPreset))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: this.selected ?
      KeyboardSkinStyle.primaryBackground(this.skinPreset, false) : KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(16)
    .clip(true)
    .systemMaterial(this.selected ? KeyboardSkinStyle.chipMaterial(this.skinPreset, true) :
      KeyboardSkinStyle.cardMaterial(this.skinPreset))
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct SkinColorSwatch {
  colorValue: string = '#FFFFFFFF';
  @Prop selected: boolean = false;
  onPress: () => void = () => {};
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  build() {
    Button({ type: ButtonType.Circle, stateEffect: false }) {
      Stack() {
        Text('')
          .width(26)
          .height(26)
          .borderRadius(13)
          .backgroundColor(this.colorValue)
        if (this.selected) {
          SystemSymbolIcon({
            symbol: $r('sys.symbol.checkmark'),
            color: KeyboardSkinStyle.keyTextColor(this.skinPreset),
            iconSize: 15
          })
        }
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
    }
    .width(42)
    .height(42)
    .padding(0)
    .margin({ right: 8, top: 6 })
    .backgroundColor(this.selected ? KeyboardSkinStyle.chipBackground(this.skinPreset, true) :
      KeyboardSkinStyle.cardBackground(this.skinPreset))
    .border({ width: 1, color: this.selected ? KeyboardSkinStyle.primaryBackground(this.skinPreset, false) :
      KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(21)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.cardMaterial(this.skinPreset))
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct SkinAreaChip {
  title: ResourceStr = '';
  @Prop active: boolean = false;
  onPress: () => void = () => {};
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  build() {
    Button({ type: ButtonType.Capsule, stateEffect: false }) {
      Text(this.title)
        .fontSize(12)
        .fontWeight(this.active ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.active ? KeyboardSkinStyle.keyTextColor(this.skinPreset) :
          KeyboardSkinStyle.mutedTextColor(this.skinPreset))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(32)
    .layoutWeight(1)
    .padding({ left: 6, right: 6 })
    .margin({ left: 3, right: 3, top: 6 })
    .backgroundColor(this.active ? KeyboardSkinStyle.chipBackground(this.skinPreset, true) :
      KeyboardSkinStyle.cardBackground(this.skinPreset))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: this.active ?
      KeyboardSkinStyle.primaryBackground(this.skinPreset, false) : KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(16)
    .clip(true)
    .systemMaterial(this.active ? KeyboardSkinStyle.chipMaterial(this.skinPreset, true) :
      KeyboardSkinStyle.cardMaterial(this.skinPreset))
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct PanelSkinEditor {
  onBack: () => void = () => {};
  @StorageLink('ime.skinPreset') skinPreset: number = KeyboardSkinPresetMode.LIQUID;
  @StorageLink('ime.skinBackgroundMode') skinBackgroundMode: number = KeyboardSkinBackgroundMode.COLOR;
  @StorageLink('ime.skinBackgroundColor') skinBackgroundColor: string = '#FFF1F4F9';
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';
  @StorageLink('ime.skinImageUri') skinImageUri: string = '';
  @StorageLink('ime.skinImagePath') skinImagePath: string = '';
  @StorageLink('ime.skinImageArea') skinImageArea: number = KeyboardSkinImageAreaMode.CENTER;
  @StorageLink('ime.skinImageBlur') skinImageBlur: number = 0;

  private applyPreset(preset: number): void {
    this.skinPreset = preset;
    this.skinBackgroundMode = KeyboardSkinBackgroundMode.COLOR;
    if (preset === KeyboardSkinPresetMode.MINT) {
      this.skinBackgroundColor = '#FFE8F7F4';
      this.skinKeyColor = '#FFE8F7F4';
    } else if (preset === KeyboardSkinPresetMode.NIGHT) {
      this.skinBackgroundColor = '#FF101824';
      this.skinKeyColor = '#55FFFFFF';
    } else if (preset === KeyboardSkinPresetMode.SUNSET) {
      this.skinBackgroundColor = '#FFFFF1E7';
      this.skinKeyColor = '#FFFFFAF2';
    } else if (preset === KeyboardSkinPresetMode.RAINBOW) {
      this.skinBackgroundColor = '#FFF8F9FA';
      this.skinKeyColor = '#FF9966FF';
    } else if (preset === KeyboardSkinPresetMode.RAINBOW_TEXT) {
      this.skinBackgroundColor = '#FFF8F9FA';
      this.skinKeyColor = '#F2FFFFFF';
    } else {
      this.skinBackgroundColor = '#FFF1F4F9';
      this.skinKeyColor = '#F2FFFFFF';
    }
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinPreset(), preset);
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinBackgroundMode(), KeyboardSkinBackgroundMode.COLOR);
    SettingsStore.updateString(SettingsStore.settingsKeySkinBackgroundColor(), this.skinBackgroundColor);
    SettingsStore.updateString(SettingsStore.settingsKeySkinKeyColor(), this.skinKeyColor);
  }

  private setCustomBackgroundColor(color: string): void {
    this.skinPreset = KeyboardSkinPresetMode.CUSTOM;
    this.skinBackgroundMode = KeyboardSkinBackgroundMode.COLOR;
    this.skinBackgroundColor = color;
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinPreset(), KeyboardSkinPresetMode.CUSTOM);
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinBackgroundMode(), KeyboardSkinBackgroundMode.COLOR);
    SettingsStore.updateString(SettingsStore.settingsKeySkinBackgroundColor(), color);
  }

  private setCustomKeyColor(color: string): void {
    this.skinPreset = KeyboardSkinPresetMode.CUSTOM;
    this.skinKeyColor = color;
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinPreset(), KeyboardSkinPresetMode.CUSTOM);
    SettingsStore.updateString(SettingsStore.settingsKeySkinKeyColor(), color);
  }

  private setImageArea(area: number): void {
    this.skinImageArea = area;
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinImageArea(), area);
  }

  private setImageBlur(value: number): void {
    this.skinImageBlur = value;
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinImageBlur(), value);
  }

  private clearImage(): void {
    this.skinImageUri = '';
    this.skinImagePath = '';
    this.skinBackgroundMode = KeyboardSkinBackgroundMode.COLOR;
    SettingsStore.clearSkinImage();
  }

  @Builder
  private SectionLabel(title: ResourceStr): void {
    Text(title)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
      .width('100%')
      .margin({ left: 6, top: 10, bottom: 2 })
  }

  @Builder
  private ImageActionButton(title: ResourceStr, symbol: Resource, enabledValue: boolean, action: () => void): void {
    Button({ type: ButtonType.Capsule, stateEffect: false }) {
      Row() {
        SystemSymbolIcon({
          symbol: symbol,
          color: KeyboardSkinStyle.keyTextColor(this.skinPreset),
          iconSize: 16
        })
        Text(title)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
          .margin({ left: 5 })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .height(36)
    .layoutWeight(1)
    .padding({ left: 8, right: 8 })
    .margin({ left: 4, right: 4, top: 6 })
    .backgroundColor(KeyboardSkinStyle.cardBackground(this.skinPreset))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.cardMaterial(this.skinPreset))
    .enabled(enabledValue)
    .opacity(enabledValue ? 1 : 0.45)
    .onClick(() => {
      action();
    })
  }

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: false }) {
          SystemSymbolIcon({
            symbol: $r('sys.symbol.chevron_left'),
            color: KeyboardSkinStyle.keyTextColor(this.skinPreset),
            iconSize: 18
          })
        }
        .width(32)
        .height(32)
        .padding(0)
        .backgroundColor(KeyboardSkinStyle.cardBackground(this.skinPreset))
        .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
        .borderRadius(16)
        .clip(true)
        .systemMaterial(KeyboardSkinStyle.cardMaterial(this.skinPreset))
        .onClick(() => {
          this.onBack();
        })

        Text($r('app.string.skin_editor_title'))
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
          .margin({ left: 10 })

        Blank()
      }
      .width('100%')
      .height(38)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 4, right: 4 })

      Scroll() {
        Column() {
          this.SectionLabel($r('app.string.skin_presets'))
          Row() {
            SkinPresetButton({
              title: $r('app.string.skin_preset_liquid'),
              backgroundColorValue: '#FFF1F4F9',
              keyColorValue: '#F2FFFFFF',
              selected: this.skinPreset === KeyboardSkinPresetMode.LIQUID,
              onPress: () => {
                this.applyPreset(KeyboardSkinPresetMode.LIQUID);
              }
            })
            SkinPresetButton({
              title: $r('app.string.skin_preset_mint'),
              backgroundColorValue: '#FFE8F7F4',
              keyColorValue: '#FFE8F7F4',
              selected: this.skinPreset === KeyboardSkinPresetMode.MINT,
              onPress: () => {
                this.applyPreset(KeyboardSkinPresetMode.MINT);
              }
            })
            SkinPresetButton({
              title: $r('app.string.skin_preset_night'),
              backgroundColorValue: '#FF101824',
              keyColorValue: '#55FFFFFF',
              selected: this.skinPreset === KeyboardSkinPresetMode.NIGHT,
              onPress: () => {
                this.applyPreset(KeyboardSkinPresetMode.NIGHT);
              }
            })
            SkinPresetButton({
              title: $r('app.string.skin_preset_sunset'),
              backgroundColorValue: '#FFFFF1E7',
              keyColorValue: '#FFFFFAF2',
              selected: this.skinPreset === KeyboardSkinPresetMode.SUNSET,
              onPress: () => {
                this.applyPreset(KeyboardSkinPresetMode.SUNSET);
              }
            })
            SkinPresetButton({
              title: $r('app.string.skin_preset_rainbow'),
              backgroundColorValue: '#FFF8F9FA',
              keyColorValue: '#FF9966FF',
              selected: this.skinPreset === KeyboardSkinPresetMode.RAINBOW,
              onPress: () => {
                this.applyPreset(KeyboardSkinPresetMode.RAINBOW);
              }
            })
            SkinPresetButton({
              title: $r('app.string.skin_preset_rainbow_text'),
              backgroundColorValue: '#FFF8F9FA',
              keyColorValue: '#F2FFFFFF',
              selected: this.skinPreset === KeyboardSkinPresetMode.RAINBOW_TEXT,
              onPress: () => {
                this.applyPreset(KeyboardSkinPresetMode.RAINBOW_TEXT);
              }
            })
          }
          .width('100%')

          this.SectionLabel($r('app.string.skin_background_color'))
          Row() {
            SkinColorSwatch({
              colorValue: '#FFF1F4F9',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFF1F4F9' &&
                this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
              onPress: () => {
                this.setCustomBackgroundColor('#FFF1F4F9');
              }
            })
            SkinColorSwatch({
              colorValue: '#FFE8F7F4',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFE8F7F4' &&
                this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
              onPress: () => {
                this.setCustomBackgroundColor('#FFE8F7F4');
              }
            })
            SkinColorSwatch({
              colorValue: '#FFFFF1E7',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFFFF1E7' &&
                this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
              onPress: () => {
                this.setCustomBackgroundColor('#FFFFF1E7');
              }
            })
            SkinColorSwatch({
              colorValue: '#FFEEEAF8',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFEEEAF8' &&
                this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
              onPress: () => {
                this.setCustomBackgroundColor('#FFEEEAF8');
              }
            })
            SkinColorSwatch({
              colorValue: '#FFFFF7D6',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFFFF7D6' &&
                this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
              onPress: () => {
                this.setCustomBackgroundColor('#FFFFF7D6');
              }
            })
            SkinColorSwatch({
              colorValue: '#FF101824',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FF101824' &&
                this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
              onPress: () => {
                this.setCustomBackgroundColor('#FF101824');
              }
            })
          }
          .width('100%')

          Row() {
            this.ImageActionButton($r('app.string.skin_choose_image_in_app'),
              $r('sys.symbol.ohos_photo'), false, () => {
            })
            this.ImageActionButton($r('app.string.skin_clear_image'), $r('sys.symbol.trash'),
              this.skinImageUri.length > 0, () => {
              this.clearImage();
            })
          }
          .width('100%')

          if (this.skinImageUri.length > 0) {
            this.SectionLabel($r('app.string.skin_image_area'))
            Row() {
              SkinAreaChip({
                title: $r('app.string.skin_area_center'),
                active: this.skinImageArea === KeyboardSkinImageAreaMode.CENTER,
                onPress: () => {
                  this.setImageArea(KeyboardSkinImageAreaMode.CENTER);
                }
              })
              SkinAreaChip({
                title: $r('app.string.skin_area_top'),
                active: this.skinImageArea === KeyboardSkinImageAreaMode.TOP,
                onPress: () => {
                  this.setImageArea(KeyboardSkinImageAreaMode.TOP);
                }
              })
              SkinAreaChip({
                title: $r('app.string.skin_area_bottom'),
                active: this.skinImageArea === KeyboardSkinImageAreaMode.BOTTOM,
                onPress: () => {
                  this.setImageArea(KeyboardSkinImageAreaMode.BOTTOM);
                }
              })
              SkinAreaChip({
                title: $r('app.string.skin_area_left'),
                active: this.skinImageArea === KeyboardSkinImageAreaMode.LEFT,
                onPress: () => {
                  this.setImageArea(KeyboardSkinImageAreaMode.LEFT);
                }
              })
              SkinAreaChip({
                title: $r('app.string.skin_area_right'),
                active: this.skinImageArea === KeyboardSkinImageAreaMode.RIGHT,
                onPress: () => {
                  this.setImageArea(KeyboardSkinImageAreaMode.RIGHT);
                }
              })
            }
            .width('100%')

            Row() {
              Text($r('app.string.skin_image_blur'))
                .width(72)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
              Slider({ value: this.skinImageBlur, min: 0, max: 20, step: 1 })
                .layoutWeight(1)
                .height(26)
                .blockColor($r('app.color.slider_block'))
                .selectedColor(KeyboardSkinStyle.primaryBackground(this.skinPreset, false))
                .trackColor($r('app.color.slider_track'))
                .onChange((value: number, mode: SliderChangeMode) => {
                  this.setImageBlur(Math.round(value));
                })
              Text(this.skinImageBlur.toString())
                .width(24)
                .fontSize(12)
                .fontColor(KeyboardSkinStyle.mutedTextColor(this.skinPreset))
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .height(38)
            .padding({ left: 10, right: 10 })
            .margin({ left: 4, right: 4, top: 6 })
            .backgroundColor(KeyboardSkinStyle.cardBackground(this.skinPreset))
            .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
            .borderRadius(16)
            .clip(true)
            .systemMaterial(KeyboardSkinStyle.cardMaterial(this.skinPreset))
            .alignItems(VerticalAlign.Center)
          }

          this.SectionLabel($r('app.string.skin_key_color'))
          Row() {
            SkinColorSwatch({
              colorValue: '#F2FFFFFF',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#F2FFFFFF',
              onPress: () => {
                this.setCustomKeyColor('#F2FFFFFF');
              }
            })
            SkinColorSwatch({
              colorValue: '#EFFFFFFF',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#EFFFFFFF',
              onPress: () => {
                this.setCustomKeyColor('#EFFFFFFF');
              }
            })
            SkinColorSwatch({
              colorValue: '#FFFFFAF2',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#FFFFFAF2',
              onPress: () => {
                this.setCustomKeyColor('#FFFFFAF2');
              }
            })
            SkinColorSwatch({
              colorValue: '#FFE8EEF8',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#FFE8EEF8',
              onPress: () => {
                this.setCustomKeyColor('#FFE8EEF8');
              }
            })
            SkinColorSwatch({
              colorValue: '#FFFFE2D4',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#FFFFE2D4',
              onPress: () => {
                this.setCustomKeyColor('#FFFFE2D4');
              }
            })
            SkinColorSwatch({
              colorValue: '#55FFFFFF',
              selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#55FFFFFF',
              onPress: () => {
                this.setCustomKeyColor('#55FFFFFF');
              }
            })
          }
          .width('100%')
          Blank().height(10)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 10, right: 10, top: 2, bottom: 2 })
  }
}

@Component
struct KeyboardPanelBackground {
  @StorageLink('ime.skinBackgroundMode') @Watch('onImageSourceChange') skinBackgroundMode: number =
    KeyboardSkinBackgroundMode.COLOR;
  @StorageLink('ime.skinImageUri') @Watch('onImageSourceChange') skinImageUri: string = '';
  @StorageLink('ime.skinImagePath') @Watch('onImageSourceChange') skinImagePath: string = '';
  @StorageLink('ime.skinImageRevision') @Watch('onImageSourceChange') skinImageRevision: string = '';
  @StorageLink('ime.skinImageArea') skinImageArea: number = KeyboardSkinImageAreaMode.CENTER;
  @StorageLink('ime.skinImageBlur') skinImageBlur: number = 0;
  @State private backgroundImageUri: string = '';
  @State private backgroundPixelMap: image.PixelMap | undefined = undefined;

  aboutToAppear(): void {
    this.reloadBackgroundImage();
  }

  private onImageSourceChange(): void {
    this.reloadBackgroundImage();
  }

  private panelFillColor(): ResourceColor {
    if (KeyboardSkinStyle.usesImageBackground(this.skinBackgroundMode, this.skinImageUri)) {
      return Color.Transparent;
    }
    return $r('app.color.kb_background');
  }

  private imagePath(): string {
    if (this.skinImagePath.length > 0) {
      return this.skinImagePath;
    }
    return this.skinImageUri;
  }

  private imageBufferFromBytes(data: Uint8Array): ArrayBuffer {
    let buffer: ArrayBuffer = new ArrayBuffer(data.length);
    let target: Uint8Array = new Uint8Array(buffer);
    for (let i: number = 0; i < data.length; i++) {
      target[i] = data[i];
    }
    return buffer;
  }

  private writeSharedDataToPanelFile(data: Uint8Array): string {
    let context: common.Context = getContext(this);
    let imagePath: string = context.filesDir + '/keyboard_skin_background.jpg';
    let imageFile: fileIo.File | undefined = undefined;
    try {
      imageFile = fileIo.openSync(imagePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE |
        fileIo.OpenMode.TRUNC);
      fileIo.writeSync(imageFile.fd, this.imageBufferFromBytes(data));
      return fileUri.getUriFromPath(imagePath);
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'write keyboard background file failed: %{public}d %{public}s', err.code,
        err.message);
    } finally {
      if (imageFile !== undefined) {
        fileIo.closeSync(imageFile);
      }
    }
    return '';
  }

  private reloadBackgroundFromSharedData(): boolean {
    let skinImageData: Uint8Array = SettingsStore.loadSkinImageData();
    if (skinImageData.length === 0) {
      return false;
    }
    let localImageUri: string = this.writeSharedDataToPanelFile(skinImageData);
    if (localImageUri.length > 0) {
      this.backgroundImageUri = localImageUri;
      this.backgroundPixelMap = undefined;
      return true;
    }
    let imageSource: image.ImageSource | undefined = undefined;
    try {
      imageSource = image.createImageSource(this.imageBufferFromBytes(skinImageData));
      this.backgroundPixelMap = imageSource.createPixelMapSync();
      return true;
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'load shared keyboard background failed: %{public}d %{public}s', err.code, err.message);
      this.backgroundPixelMap = undefined;
    } finally {
      if (imageSource !== undefined) {
        imageSource.release();
      }
    }
    return false;
  }

  private reloadBackgroundImage(): void {
    if (!KeyboardSkinStyle.usesImageBackground(this.skinBackgroundMode, this.skinImageUri)) {
      this.backgroundImageUri = '';
      this.backgroundPixelMap = undefined;
      return;
    }
    if (this.reloadBackgroundFromSharedData()) {
      return;
    }
    let path: string = this.imagePath();
    if (path.length === 0) {
      this.backgroundImageUri = '';
      this.backgroundPixelMap = undefined;
      return;
    }
    let imageFile: fileIo.File | undefined = undefined;
    let imageSource: image.ImageSource | undefined = undefined;
    try {
      imageFile = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      imageSource = image.createImageSource(imageFile.fd);
      this.backgroundImageUri = '';
      this.backgroundPixelMap = imageSource.createPixelMapSync();
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'load keyboard background failed: %{public}d %{public}s', err.code, err.message);
      this.backgroundPixelMap = undefined;
    } finally {
      if (imageSource !== undefined) {
        imageSource.release();
      }
      if (imageFile !== undefined) {
        fileIo.closeSync(imageFile);
      }
    }
  }

  @Builder
  private BackgroundImage(): void {
    if (this.backgroundImageUri.length > 0) {
      Image(this.backgroundImageUri)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .blur(this.skinImageBlur)
    } else if (this.backgroundPixelMap !== undefined) {
      Image(this.backgroundPixelMap)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .blur(this.skinImageBlur)
    } else {
      Image(this.skinImageUri)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .blur(this.skinImageBlur)
    }
  }

  @Builder
  private ImageLayer(): void {
    if (this.skinImageArea === KeyboardSkinImageAreaMode.TOP) {
      Stack({ alignContent: Alignment.Top }) {
        this.BackgroundImage()
      }
      .width('100%')
      .height('100%')
      .clip(true)
    } else if (this.skinImageArea === KeyboardSkinImageAreaMode.BOTTOM) {
      Stack({ alignContent: Alignment.Bottom }) {
        this.BackgroundImage()
      }
      .width('100%')
      .height('100%')
      .clip(true)
    } else if (this.skinImageArea === KeyboardSkinImageAreaMode.LEFT) {
      Stack({ alignContent: Alignment.Start }) {
        this.BackgroundImage()
      }
      .width('100%')
      .height('100%')
      .clip(true)
    } else if (this.skinImageArea === KeyboardSkinImageAreaMode.RIGHT) {
      Stack({ alignContent: Alignment.End }) {
        this.BackgroundImage()
      }
      .width('100%')
      .height('100%')
      .clip(true)
    } else {
      Stack({ alignContent: Alignment.Center }) {
        this.BackgroundImage()
      }
      .width('100%')
      .height('100%')
      .clip(true)
    }
  }

  build() {
    Stack() {
      if (KeyboardSkinStyle.usesImageBackground(this.skinBackgroundMode, this.skinImageUri)) {
        this.ImageLayer()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.panelFillColor())
    .borderRadius({
      topLeft: KEYBOARD_PANEL_CORNER_RADIUS,
      topRight: KEYBOARD_PANEL_CORNER_RADIUS,
      bottomLeft: 0,
      bottomRight: 0
    })
    .renderGroup(true)
    .clip(true)
  }
}

@Component
struct PanelSettings {
  @StorageLink('ime.panelSettingsTab') panelSettingsTab: number = 0;
  @StorageLink('ime.panelSettingsVisible') panelSettingsVisible: boolean = false;
  @StorageLink('ime.layoutMode') layoutMode: number = KeyboardLayoutMode.QWERTY26;
  @StorageLink('ime.keyboardHeightPercent') keyboardHeightPercent: number = 32;
  @StorageLink('ime.keyboardDockMode') keyboardDockMode: number = KeyboardDockMode.FULL;
  @StorageLink('ime.numberRow') numberRow: boolean = true;
  @StorageLink('ime.enterSend') enterSend: boolean = false;
  @StorageLink('ime.upperCase') upperCase: boolean = false;
  @StorageLink('ime.soundEffect') soundEffect: boolean = false;
  @StorageLink('ime.keyPopup') keyPopup: boolean = true;
  @StorageLink('ime.keyFontScale') keyFontScale: number = 100;
  @StorageLink('ime.fuzzyPinyin') fuzzyPinyin: boolean = false;
  @StorageLink('ime.mixedInput') mixedInput: boolean = true;
  @StorageLink('ime.securityMode') securityMode: number = inputMethodEngine.SecurityMode.BASIC;
  @Consume keyboardMode: number;
  @State private skinEditorVisible: boolean = false;

  private setPanelSettingsTab(index: number): void {
    this.panelSettingsTab = index;
  }

  private setLayoutMode(mode: number): void {
    this.layoutMode = mode;
    SettingsStore.updateLayoutMode(mode);
  }

  private setKeyboardHeightPercent(value: number): void {
    this.keyboardHeightPercent = value;
    SettingsStore.updateNumber(SettingsStore.settingsKeyKeyboardHeightPercent(), value);
    keyboardController.resizeKeyboardPanel();
  }

  private openSettings(route: string): void {
    keyboardController.openSettings(route);
  }

  private isBasicSecurityMode(): boolean {
    return this.securityMode === inputMethodEngine.SecurityMode.BASIC;
  }

  private openClipboardKeyboard(): void {
    if (this.isBasicSecurityMode()) {
      promptAction.showToast({
        message: $r('app.string.clipboard_security_mode_disabled')
      });
      return;
    }
    this.keyboardMode = KeyboardMode.CLIPBOARD;
    this.panelSettingsVisible = false;
  }

  private switchInputMethod(): void {
    keyboardController.switchToNextInputMethod().then((switched: boolean) => {
      if (!switched) {
        promptAction.showToast({
          message: $r('app.string.switch_input_method_unavailable')
        });
      }
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'switch input method failed: %{public}d %{public}s', err.code, err.message);
      promptAction.showToast({
        message: $r('app.string.switch_input_method_failed')
      });
    });
  }

  private setKeyboardDockMode(mode: number): void {
    this.keyboardDockMode = mode;
    SettingsStore.updateNumber(SettingsStore.settingsKeyKeyboardDockMode(), mode);
  }

  private cycleKeyboardDockMode(): void {
    if (this.keyboardDockMode === KeyboardDockMode.FULL) {
      this.setKeyboardDockMode(KeyboardDockMode.LEFT);
    } else if (this.keyboardDockMode === KeyboardDockMode.LEFT) {
      this.setKeyboardDockMode(KeyboardDockMode.RIGHT);
    } else {
      this.setKeyboardDockMode(KeyboardDockMode.FULL);
    }
  }

  private cycleKeyFontScale(): void {
    let nextScale: number = 100;
    if (this.keyFontScale < 105) {
      nextScale = 110;
    } else if (this.keyFontScale < 115) {
      nextScale = 120;
    }
    this.keyFontScale = nextScale;
    SettingsStore.updateNumber(SettingsStore.settingsKeyKeyFontScale(), nextScale);
    promptAction.showToast({
      message: nextScale.toString() + '%'
    });
  }

  private toggleNumberRow(): void {
    let value: boolean = !this.numberRow;
    this.numberRow = value;
    SettingsStore.updateBoolean(SettingsStore.settingsKeyNumberRow(), value);
  }

  private toggleEnterSend(): void {
    let value: boolean = !this.enterSend;
    this.enterSend = value;
    SettingsStore.updateBoolean(SettingsStore.settingsKeyEnterSend(), value);
  }

  private toggleUpperCase(): void {
    let value: boolean = !this.upperCase;
    this.upperCase = value;
    SettingsStore.updateBoolean(SettingsStore.settingsKeyUpperCase(), value);
  }

  private toggleSoundEffect(): void {
    let value: boolean = !this.soundEffect;
    this.soundEffect = value;
    SettingsStore.updateBoolean(SettingsStore.settingsKeySoundEffect(), value);
  }

  private toggleKeyPopup(): void {
    let value: boolean = !this.keyPopup;
    this.keyPopup = value;
    SettingsStore.updateBoolean(SettingsStore.settingsKeyKeyPopup(), value);
  }

  private toggleFuzzyPinyin(): void {
    let value: boolean = !this.fuzzyPinyin;
    this.fuzzyPinyin = value;
    SettingsStore.updateBoolean(SettingsStore.settingsKeyFuzzyPinyin(), value);
    pinyinEngine.refreshForSettings();
  }

  private toggleMixedInput(): void {
    let value: boolean = !this.mixedInput;
    this.mixedInput = value;
    SettingsStore.updateBoolean(SettingsStore.settingsKeyMixedInput(), value);
    pinyinEngine.refreshForSettings();
  }

  build() {
    Column() {
      if (this.skinEditorVisible) {
        PanelSkinEditor({
          onBack: () => {
            this.skinEditorVisible = false;
          }
        })
      } else {
        Scroll() {
          Column() {
            if (this.panelSettingsTab === 0) {
              this.buildCommonPanel()
            } else if (this.panelSettingsTab === 1) {
              this.buildInputPanel()
            } else {
              this.buildKeyboardPanel()
            }
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        if (this.panelSettingsTab === 2) {
          PanelHeightSlider({
            value: this.keyboardHeightPercent,
            min: 24,
            max: 42,
            onChange: (value: number) => {
              this.setKeyboardHeightPercent(value);
            }
          })
        }

        Row() {
          PanelPageDot({ active: this.panelSettingsTab === 0 })
          PanelPageDot({ active: this.panelSettingsTab === 1 })
          PanelPageDot({ active: this.panelSettingsTab === 2 })
        }
        .width('100%')
        .height(16)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 3 })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 10, right: 10, top: 2, bottom: 2 })
  }

  @Builder
  private buildCommonPanel(): void {
    Column() {
      Row() {
        PanelSettingCard({
          title: $r('app.string.panel_help_feedback'),
          symbol: $r('sys.symbol.questionmark_circle'),
          onPress: () => {
            this.openSettings(ROUTE_HELP);
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_settings'),
          symbol: $r('sys.symbol.gearshape'),
          onPress: () => {
            this.openSettings(ROUTE_SETTINGS_HOME);
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_switch_input_method'),
          symbol: $r('sys.symbol.keyboard_badge_globe'),
          onPress: () => {
            this.switchInputMethod();
          }
        })
      }
      .width('100%')

      Row() {
        PanelSettingCard({
          title: $r('app.string.panel_clipboard'),
          symbol: $r('sys.symbol.text_clipboard'),
          itemEnabled: !this.isBasicSecurityMode(),
          onPress: () => {
            this.openClipboardKeyboard();
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_emoji_keyboard'),
          symbol: $r('sys.symbol.face_smiling'),
          onPress: () => {
            this.keyboardMode = KeyboardMode.EMOJI;
            this.panelSettingsVisible = false;
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_edit_keyboard'),
          symbol: $r('sys.symbol.rectangle_grid_2x1'),
          onPress: () => {
            this.keyboardMode = KeyboardMode.EDIT;
            this.panelSettingsVisible = false;
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_dictionary'),
          symbol: $r('sys.symbol.book'),
          onPress: () => {
            this.openSettings(ROUTE_DICTIONARY);
          }
        })
      }
      .width('100%')

      Row() {
        PanelSettingCard({
          title: $r('app.string.panel_font_size'),
          symbol: $r('sys.symbol.textformat_size_square'),
          active: this.keyFontScale > 100,
          onPress: () => {
            this.cycleKeyFontScale();
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_sound_vibration'),
          symbol: $r('sys.symbol.waveform_left_speaker_waveform_right'),
          active: this.soundEffect,
          onPress: () => {
            this.toggleSoundEffect();
            this.openSettings(ROUTE_KEY_EFFECT);
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_skin'),
          symbol: $r('sys.symbol.shirt'),
          onPress: () => {
            this.skinEditorVisible = true;
          }
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildInputPanel(): void {
    Column() {
      Row() {
        PanelSettingCard({
          title: $r('app.string.layout_26'),
          symbol: $r('sys.symbol.keyboard_badge_26'),
          active: this.layoutMode === KeyboardLayoutMode.QWERTY26,
          onPress: () => {
            this.setLayoutMode(KeyboardLayoutMode.QWERTY26);
          }
        })
        PanelSettingCard({
          title: $r('app.string.layout_9'),
          symbol: $r('sys.symbol.keyboard_badge_9'),
          active: this.layoutMode === KeyboardLayoutMode.T9,
          onPress: () => {
            this.setLayoutMode(KeyboardLayoutMode.T9);
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_double_pinyin'),
          symbol: $r('sys.symbol.keyboard_badge_spell'),
          active: this.layoutMode === KeyboardLayoutMode.XIAOHE_SHUANGPIN,
          onPress: () => {
            this.setLayoutMode(KeyboardLayoutMode.XIAOHE_SHUANGPIN);
          }
        })
        PanelSettingCard({
          title: $r('app.string.layout_title'),
          symbol: $r('sys.symbol.keyboard_badge_gearshape'),
          onPress: () => {
            this.openSettings(ROUTE_KEYBOARD_MANAGE);
          }
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildKeyboardPanel(): void {
    Column() {
      Row() {
        PanelSettingCard({
          title: $r('app.string.panel_letter_keyboard'),
          symbol: $r('sys.symbol.keyboard'),
          active: this.keyboardMode === KeyboardMode.LETTER,
          onPress: () => {
            this.keyboardMode = KeyboardMode.LETTER;
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_number_keyboard'),
          symbol: $r('sys.symbol.keyboard_badge_9'),
          active: this.keyboardMode === KeyboardMode.NUMBER,
          onPress: () => {
            this.keyboardMode = KeyboardMode.NUMBER;
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_symbol_keyboard'),
          symbol: $r('sys.symbol.keyboard_square'),
          active: this.keyboardMode === KeyboardMode.SYMBOL,
          onPress: () => {
            this.keyboardMode = KeyboardMode.SYMBOL;
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_edit_keyboard'),
          symbol: $r('sys.symbol.rectangle_grid_2x1'),
          active: this.keyboardMode === KeyboardMode.EDIT,
          onPress: () => {
            this.keyboardMode = KeyboardMode.EDIT;
          }
        })
      }
      .width('100%')

      Row() {
        PanelSettingCard({
          title: $r('app.string.panel_onehand_left'),
          symbol: $r('sys.symbol.keyboard_onehanded_left'),
          active: this.keyboardDockMode === KeyboardDockMode.LEFT,
          onPress: () => {
            this.setKeyboardDockMode(KeyboardDockMode.LEFT);
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_onehand_right'),
          symbol: $r('sys.symbol.keyboard_onehanded_right'),
          active: this.keyboardDockMode === KeyboardDockMode.RIGHT,
          onPress: () => {
            this.setKeyboardDockMode(KeyboardDockMode.RIGHT);
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_full_keyboard'),
          symbol: $r('sys.symbol.keyboard_badge_full'),
          active: this.keyboardDockMode === KeyboardDockMode.FULL,
          onPress: () => {
            this.setKeyboardDockMode(KeyboardDockMode.FULL);
          }
        })
        PanelSettingCard({
          title: $r('app.string.panel_keyboard_move'),
          symbol: $r('sys.symbol.keyboard_move'),
          onPress: () => {
            this.cycleKeyboardDockMode();
          }
        })
      }
      .width('100%')
    }
    .width('100%')
  }
}

@Entry
@Component
struct Index {
  @Provide shiftState: number = ShiftState.OFF;
  @Provide keyboardMode: number = KeyboardMode.LETTER;
  @StorageLink('ime.layoutMode') layoutMode: number = KeyboardLayoutMode.QWERTY26;
  @StorageLink('ime.keyboardDockMode') keyboardDockMode: number = KeyboardDockMode.FULL;
  @StorageLink('inputPattern') @Watch('onInputPatternChange') inputPattern: number = 0;
  @StorageLink('ime.panelSettingsVisible') panelSettingsVisible: boolean = false;
  @StorageLink('ime.skinPreset') skinPreset: number = KeyboardSkinPresetMode.LIQUID;
  @StorageLink('ime.skinBackgroundMode') skinBackgroundMode: number = KeyboardSkinBackgroundMode.COLOR;
  @StorageLink('ime.skinImageUri') skinImageUri: string = '';

  aboutToAppear(): void {
    SettingsStore.reloadSettings();
  }

  // InputType.Number=2, InputType.PhoneNumber=3 — 这两种自动切到数字键盘
  onInputPatternChange(): void {
    if (this.inputPattern === 2 || this.inputPattern === 3) {
      this.keyboardMode = KeyboardMode.NUMBER;
    } else {
      this.keyboardMode = KeyboardMode.LETTER;
    }
  }

  onBackPress(): boolean {
    InputHandler.getInstance().hideKeyboardSelf();
    return true;
  }

  private panelRootBackground(): ResourceColor {
    if (KeyboardSkinStyle.usesImageBackground(this.skinBackgroundMode, this.skinImageUri)) {
      return Color.Transparent;
    }
    return $r('app.color.kb_background');
  }

  private panelAlignment(): Alignment {
    if (this.keyboardDockMode === KeyboardDockMode.LEFT) {
      return Alignment.Start;
    }
    if (this.keyboardDockMode === KeyboardDockMode.RIGHT) {
      return Alignment.End;
    }
    return Alignment.Center;
  }

  private panelWidth(): string {
    if (this.keyboardDockMode === KeyboardDockMode.FULL) {
      return '100%';
    }
    return '86%';
  }

  build() {
    Stack({ alignContent: this.panelAlignment() }) {
      Stack() {
        KeyboardPanelBackground()
          .zIndex(1)
        Column() {
          TopBar()
          Stack() {
            if (this.panelSettingsVisible) {
              PanelSettings()
            } else {
              if (this.keyboardMode === KeyboardMode.LETTER) {
                if (this.layoutMode === KeyboardLayoutMode.T9) {
                  T9Keyboard()
                } else {
                  LetterKeyboard()
                }
              } else if (this.keyboardMode === KeyboardMode.NUMBER) {
                NumberKeyboard()
              } else if (this.keyboardMode === KeyboardMode.SYMBOL) {
                SymbolKeyboard()
              } else if (this.keyboardMode === KeyboardMode.CLIPBOARD) {
                ClipboardKeyboard()
              } else if (this.keyboardMode === KeyboardMode.EMOJI) {
                EmojiKeyboard()
              } else {
                EditKeyboard()
              }
            }
          }
          .width('100%')
          .layoutWeight(1)
          .alignContent(Alignment.Top)
        }
        .width('100%')
        .height('100%')
        .zIndex(2)
      }
      .width(this.panelWidth())
      .height('100%')
      .backgroundColor(this.panelRootBackground())
      .borderRadius({
        topLeft: KEYBOARD_PANEL_CORNER_RADIUS,
        topRight: KEYBOARD_PANEL_CORNER_RADIUS,
        bottomLeft: 0,
        bottomRight: 0
      })
      .clip(true)
      .systemMaterial(KeyboardSkinStyle.panelMaterial(this.skinPreset))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }
}
