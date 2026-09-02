import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { inputMethod } from '@kit.IMEKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { systemShare } from '@kit.ShareKit';
import {
  HdsNavigationTitle,
  HdsNavigationTitleBarOptions,
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  TitleBarContentOptions,
  TitleBarStyleOptions
} from '@kit.UIDesignKit';
import { LiquidMaterial } from '../common/LiquidMaterial';
import { HdsMaterialStyle } from '../common/HdsMaterialStyle';
import {
  KeyboardLayoutMode,
  KeyboardDockMode,
  ImeSettings,
  KeyboardSkinBackgroundMode,
  KeyboardSkinImageAreaMode,
  KeyboardSkinPresetMode,
  SettingsStore,
  SystemMaterialLevelMode
} from '../model/ImeSettings';
import {
  SETTINGS_LAUNCH_ROUTE_KEY,
  ROUTE_LAYOUT_DISPLAY,
  ROUTE_KEY_EFFECT,
  ROUTE_TOOLBAR,
  ROUTE_ASSIST_INPUT,
  ROUTE_KEYBOARD_MANAGE,
  ROUTE_SPEECH_TEXT,
  ROUTE_SKIN,
  ROUTE_DICTIONARY,
  ROUTE_SYSTEM_MATERIAL,
  ROUTE_ABOUT,
  ROUTE_HELP
} from '../model/SettingsLaunch';
import { SystemSymbolIcon } from '../components/SystemSymbolIcon';
import { pinyinEngine } from '../model/PinyinEngine';

const TAG: string = 'SettingsIndex';
const SKIN_IMAGE_TARGET_WIDTH: number = 960;
const SKIN_IMAGE_TARGET_HEIGHT: number = 640;
const SKIN_IMAGE_PACK_QUALITY: number = 82;
const SKIN_IMAGE_PACK_BUFFER_SIZE: number = 2 * 1024 * 1024;
const READ_PASTEBOARD_PERMISSION: Permissions = 'ohos.permission.READ_PASTEBOARD';

class HdsTitleConfig implements HdsNavigationTitle {
  mainTitle: ResourceStr = '';
  subTitle: ResourceStr | undefined = undefined;
}

class HdsTitleBarContentConfig implements TitleBarContentOptions {
  title: HdsNavigationTitle | undefined = undefined;
}

class HdsTitleBarOptionsConfig implements HdsNavigationTitleBarOptions {
  avoidLayoutSafeArea: boolean = true;
  content: TitleBarContentOptions | undefined = undefined;
  style: TitleBarStyleOptions | undefined = undefined;
}

class StoredSkinImage {
  uri: string = '';
  path: string = '';
  data: Uint8Array = new Uint8Array(0);
}

@Component
struct HomeOptionCard {
  title: ResourceStr = '';
  subtitle: ResourceStr = '';
  symbol: Resource = $r('sys.symbol.keyboard');
  onPress: () => void = () => {};

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Column() {
        SystemSymbolIcon({
          symbol: this.symbol,
          color: $r('app.color.text_secondary'),
          iconSize: 30
        })

        Row() {
          Text(this.title)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.key_text'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          SystemSymbolIcon({
            symbol: $r('sys.symbol.chevron_right'),
            color: $r('app.color.text_muted'),
            iconSize: 18
          })
            .margin({ left: 4 })
        }
        .width('100%')
        .margin({ top: 28 })
        .alignItems(VerticalAlign.Center)

        Text(this.subtitle)
          .fontSize(15)
          .fontColor($r('app.color.text_muted'))
          .lineHeight(23)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 8 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .height(158)
    .layoutWeight(1)
    .padding(20)
    .margin({ left: 6, right: 6, top: 12 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct MoreOptionCard {
  title: ResourceStr = '';
  symbol: Resource = $r('sys.symbol.info_circle');
  onPress: () => void = () => {};

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Column() {
        SystemSymbolIcon({
          symbol: this.symbol,
          color: $r('app.color.text_secondary'),
          iconSize: 30
        })
        Row() {
          Text(this.title)
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.key_text'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          SystemSymbolIcon({
            symbol: $r('sys.symbol.chevron_right'),
            color: $r('app.color.text_muted'),
            iconSize: 16
          })
            .margin({ left: 4 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 24 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .height(112)
    .layoutWeight(1)
    .padding(20)
    .margin({ left: 6, right: 6, top: 12 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct SectionTitle {
  title: ResourceStr = '';

  build() {
    Text(this.title)
      .fontSize(24)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.key_text'))
      .width('100%')
      .margin({ left: 6, top: 26, bottom: 2 })
  }
}

@Component
struct PreferenceSwitch {
  title: ResourceStr = '';
  subtitle: ResourceStr = '';
  @Prop @Watch('onValueChange') value: boolean = false;
  onChange: (value: boolean) => void = (value: boolean) => {};
  @State private currentValue: boolean = false;

  aboutToAppear(): void {
    this.currentValue = this.value;
  }

  onValueChange(): void {
    this.currentValue = this.value;
  }

  build() {
    Row() {
      Column() {
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.key_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.subtitle)
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .lineHeight(19)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.currentValue })
        .selectedColor($r('app.color.material_primary'))
        .onChange((isOn: boolean) => {
          this.currentValue = isOn;
          this.onChange(isOn);
        })
    }
    .width('100%')
    .height(82)
    .padding({ left: 18, right: 16, top: 12, bottom: 12 })
    .margin({ top: 10 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct PreferenceSlider {
  title: ResourceStr = '';
  @Prop @Watch('onValueChange') value: number = 0;
  min: number = 0;
  max: number = 100;
  unit: string = '';
  onChange: (value: number) => void = (value: number) => {};
  @State private currentValue: number = 0;

  aboutToAppear(): void {
    this.currentValue = this.value;
  }

  onValueChange(): void {
    this.currentValue = this.value;
  }

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.key_text'))
        Blank()
        Text(this.currentValue.toString() + this.unit)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Slider({ value: this.currentValue, min: this.min, max: this.max, step: 1 })
        .width('100%')
        .blockColor($r('app.color.slider_block'))
        .selectedColor($r('app.color.material_primary'))
        .trackColor($r('app.color.slider_track'))
        .margin({ top: 14 })
        .onChange((value: number, mode: SliderChangeMode) => {
          let roundedValue: number = Math.round(value);
          this.currentValue = roundedValue;
          this.onChange(roundedValue);
        })
    }
    .width('100%')
    .padding(18)
    .margin({ top: 10 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
  }
}

@Component
struct ChoiceCard {
  title: ResourceStr = '';
  subtitle: ResourceStr = '';
  symbol: Resource = $r('sys.symbol.keyboard');
  @Prop selected: boolean = false;
  @Prop itemEnabled: boolean = true;
  onPress: () => void = () => {};

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Column() {
        Row() {
          SystemSymbolIcon({
            symbol: this.symbol,
            color: this.selected ? $r('app.color.material_primary') : $r('app.color.text_secondary'),
            iconSize: 26
          })
          Blank()
          if (this.selected) {
            SystemSymbolIcon({
              symbol: $r('sys.symbol.checkmark_circle_fill'),
              color: $r('app.color.accent_green'),
              iconSize: 20
            })
          }
        }
        .width('100%')

        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.itemEnabled ? $r('app.color.key_text') : $r('app.color.text_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 16 })

        Text(this.subtitle)
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 5 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .height(120)
    .layoutWeight(1)
    .padding(16)
    .margin({ left: 5, right: 5, top: 10 })
    .backgroundColor(this.selected ? LiquidMaterial.chipBackground(true) : LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(this.selected ? LiquidMaterial.chip(true) : LiquidMaterial.card())
    .opacity(this.itemEnabled ? 1 : 0.42)
    .enabled(this.itemEnabled)
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct InfoOptionRow {
  title: ResourceStr = '';
  subtitle: ResourceStr = '';
  symbol: Resource = $r('sys.symbol.info_circle');
  enabledText: ResourceStr = '';
  hasEnabledText: boolean = false;

  build() {
    Row() {
      Stack() {
        SystemSymbolIcon({
          symbol: this.symbol,
          color: $r('app.color.text_secondary'),
          iconSize: 24
        })
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor($r('app.color.settings_icon_background'))

      Column() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.key_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.subtitle)
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .lineHeight(19)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      if (this.hasEnabledText) {
        Text(this.enabledText)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(12)
          .backgroundColor($r('app.color.settings_icon_background'))
      }
    }
    .width('100%')
    .height(84)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .margin({ top: 10 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct ActionOptionRow {
  title: ResourceStr = '';
  subtitle: ResourceStr = '';
  symbol: Resource = $r('sys.symbol.info_circle');
  onPress: () => void = () => {};

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Row() {
        Stack() {
          SystemSymbolIcon({
            symbol: this.symbol,
            color: $r('app.color.text_secondary'),
            iconSize: 24
          })
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor($r('app.color.settings_icon_background'))

        Column() {
          Text(this.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.key_text'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.subtitle)
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
            .lineHeight(19)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })

        SystemSymbolIcon({
          symbol: $r('sys.symbol.chevron_right'),
          color: $r('app.color.text_muted'),
          iconSize: 16
        })
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(84)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .margin({ top: 10 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct DestructiveOptionRow {
  title: ResourceStr = '';
  subtitle: ResourceStr = '';
  symbol: Resource = $r('sys.symbol.trash');
  @Prop itemEnabled: boolean = true;
  onPress: () => void = () => {};

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Row() {
        Stack() {
          SystemSymbolIcon({
            symbol: this.symbol,
            color: $r('app.color.danger'),
            iconSize: 24
          })
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor($r('app.color.settings_icon_background'))

        Column() {
          Text(this.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.itemEnabled ? $r('app.color.danger') : $r('app.color.text_muted'))
          Text(this.subtitle)
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
            .lineHeight(19)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })

        SystemSymbolIcon({
          symbol: $r('sys.symbol.chevron_right'),
          color: $r('app.color.text_muted'),
          iconSize: 16
        })
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(84)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .margin({ top: 10 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
    .enabled(this.itemEnabled)
    .opacity(this.itemEnabled ? 1 : 0.5)
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct MaterialLevelCard {
  title: ResourceStr = '';
  subtitle: ResourceStr = '';
  @Prop selected: boolean = false;
  @Prop itemEnabled: boolean = true;
  onPress: () => void = () => {};

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Row() {
        Column() {
          Text(this.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.itemEnabled ? $r('app.color.key_text') : $r('app.color.text_muted'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.subtitle)
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(19)
            .margin({ top: 5 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        SystemSymbolIcon({
          symbol: this.selected ? $r('sys.symbol.checkmark_circle_fill') : $r('sys.symbol.circle'),
          color: this.selected ? $r('app.color.accent_green') : $r('app.color.text_muted'),
          iconSize: 22
        })
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(82)
    .padding({ left: 18, right: 16 })
    .margin({ top: 10 })
    .backgroundColor(this.selected ? LiquidMaterial.chipBackground(true) : LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(this.selected ? LiquidMaterial.chip(true) : LiquidMaterial.card())
    .enabled(this.itemEnabled)
    .opacity(this.itemEnabled ? 1 : 0.45)
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct SettingsSkinPresetCard {
  title: ResourceStr = '';
  backgroundColorValue: string = '#FFF1F4F9';
  keyColorValue: string = '#F2FFFFFF';
  @Prop selected: boolean = false;
  onPress: () => void = () => {};

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
              .height(20)
              .borderRadius(8)
              .backgroundColor(this.keyColorValue)
            Blank()
              .layoutWeight(1)
              .height(20)
              .borderRadius(8)
              .backgroundColor(this.keyColorValue)
              .margin({ left: 6 })
            Blank()
              .layoutWeight(1)
              .height(20)
              .borderRadius(8)
              .backgroundColor(this.keyColorValue)
              .margin({ left: 6 })
          }
          .width('82%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(48)
        .borderRadius(14)
        .clip(true)

        Text(this.title)
          .fontSize(13)
          .fontWeight(this.selected ? FontWeight.Bold : FontWeight.Medium)
          .fontColor($r('app.color.key_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .height(90)
    .layoutWeight(1)
    .padding(8)
    .margin({ left: 5, right: 5, top: 10 })
    .backgroundColor(this.selected ? LiquidMaterial.chipBackground(true) : LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: this.selected ? $r('app.color.material_primary') :
      LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(this.selected ? LiquidMaterial.chip(true) : LiquidMaterial.card())
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct SettingsSkinColorSwatch {
  colorValue: string = '#FFFFFFFF';
  @Prop selected: boolean = false;
  onPress: () => void = () => {};

  build() {
    Button({ type: ButtonType.Circle, stateEffect: false }) {
      Stack() {
        Text('')
          .width(30)
          .height(30)
          .borderRadius(15)
          .backgroundColor(this.colorValue)
        if (this.selected) {
          SystemSymbolIcon({
            symbol: $r('sys.symbol.checkmark'),
            color: $r('app.color.key_text'),
            iconSize: 16
          })
        }
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
    }
    .width(48)
    .height(48)
    .padding(0)
    .margin({ right: 8, top: 8 })
    .backgroundColor(this.selected ? LiquidMaterial.chipBackground(true) : LiquidMaterial.cardBackground())
    .border({ width: 1, color: this.selected ? $r('app.color.material_primary') : LiquidMaterial.borderColor() })
    .borderRadius(24)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct SettingsSkinAreaChip {
  title: ResourceStr = '';
  @Prop selected: boolean = false;
  onPress: () => void = () => {};

  build() {
    Button({ type: ButtonType.Capsule, stateEffect: false }) {
      Text(this.title)
        .fontSize(12)
        .fontWeight(this.selected ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selected ? $r('app.color.key_text') : $r('app.color.text_muted'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(34)
    .layoutWeight(1)
    .padding({ left: 6, right: 6 })
    .margin({ left: 3, right: 3, top: 8 })
    .backgroundColor(this.selected ? LiquidMaterial.chipBackground(true) : LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: this.selected ? $r('app.color.material_primary') :
      LiquidMaterial.borderColor() })
    .borderRadius(17)
    .clip(true)
    .systemMaterial(this.selected ? LiquidMaterial.chip(true) : LiquidMaterial.card())
    .onClick(() => {
      this.onPress();
    })
  }
}

@Component
struct SettingsSkinActionButton {
  title: ResourceStr = '';
  symbol: Resource = $r('sys.symbol.ohos_photo');
  @Prop enabledValue: boolean = true;
  onPress: () => void = () => {};

  build() {
    Button({ type: ButtonType.Capsule, stateEffect: false }) {
      Row() {
        SystemSymbolIcon({
          symbol: this.symbol,
          color: $r('app.color.key_text'),
          iconSize: 17
        })
        Text(this.title)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.key_text'))
          .margin({ left: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .height(42)
    .layoutWeight(1)
    .padding({ left: 8, right: 8 })
    .margin({ left: 5, right: 5, top: 10 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(21)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
    .enabled(this.enabledValue)
    .opacity(this.enabledValue ? 1 : 0.45)
    .onClick(() => {
      this.onPress();
    })
  }
}

@Entry
@Component
struct Index {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @StorageLink('topRectHeight') topRectHeight: number = 0;
  @StorageLink('ime.systemMaterialEnabled') systemMaterialEnabled: boolean = true;
  @StorageLink('ime.systemMaterialLevel') systemMaterialLevel: number = SystemMaterialLevelMode.REGULAR;
  @StorageLink(SETTINGS_LAUNCH_ROUTE_KEY) @Watch('onLaunchRouteChange') launchRoute: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    let context: common.Context = getContext(this);
    SettingsStore.init(context);
    this.consumeLaunchRoute();
  }

  private topInset(): number {
    return this.getUIContext().px2vp(this.topRectHeight) + 12;
  }

  private pushPage(name: string): void {
    this.pageStack.pushPath({ name: name });
  }

  private onLaunchRouteChange(): void {
    this.consumeLaunchRoute();
  }

  private consumeLaunchRoute(): void {
    if (this.launchRoute.length === 0) {
      return;
    }
    let route: string = this.launchRoute;
    this.launchRoute = '';
    if (this.isKnownDetailRoute(route)) {
      this.pushPage(route);
    }
  }

  private isKnownDetailRoute(route: string): boolean {
    return route === ROUTE_LAYOUT_DISPLAY || route === ROUTE_KEY_EFFECT || route === ROUTE_TOOLBAR ||
      route === ROUTE_ASSIST_INPUT || route === ROUTE_KEYBOARD_MANAGE || route === ROUTE_SPEECH_TEXT ||
      route === ROUTE_SKIN || route === ROUTE_DICTIONARY || route === ROUTE_SYSTEM_MATERIAL ||
      route === ROUTE_ABOUT || route === ROUTE_HELP;
  }

  private titleBarOptions(): HdsNavigationTitleBarOptions {
    let title: HdsTitleConfig = new HdsTitleConfig();
    title.mainTitle = $r('app.string.settings_title');
    title.subTitle = $r('app.string.settings_nav_subtitle');

    let content: HdsTitleBarContentConfig = new HdsTitleBarContentConfig();
    content.title = title;

    let options: HdsTitleBarOptionsConfig = new HdsTitleBarOptionsConfig();
    options.content = content;
    options.style = HdsMaterialStyle.titleBarStyle(this.systemMaterialEnabled, this.systemMaterialLevel);
    return options;
  }

  @Builder
  private AppIdentity(): void {
    Row() {
      Image($r('app.media.icon_liquid'))
        .width(68)
        .height(68)
        .borderRadius(34)
        .margin({ right: 18 })
      Column() {
        Text($r('app.string.settings_title'))
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.key_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text($r('app.string.settings_nav_subtitle'))
          .fontSize(16)
          .fontColor($r('app.color.text_muted'))
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 6, right: 6, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private HomeContent(): void {
    Scroll(this.scroller) {
      Column() {
        Blank()
          .height(this.topInset())
          .width('100%')
        this.AppIdentity()

        SectionTitle({ title: $r('app.string.home_section_settings') })
        Row() {
          HomeOptionCard({
            title: $r('app.string.home_layout_display'),
            subtitle: $r('app.string.home_layout_display_desc'),
            symbol: $r('sys.symbol.keyboard_badge_gearshape'),
            onPress: () => {
              this.pushPage(ROUTE_LAYOUT_DISPLAY);
            }
          })
          HomeOptionCard({
            title: $r('app.string.home_key_effect'),
            subtitle: $r('app.string.home_key_effect_desc'),
            symbol: $r('sys.symbol.waveform_left_speaker_waveform_right'),
            onPress: () => {
              this.pushPage(ROUTE_KEY_EFFECT);
            }
          })
        }
        .width('100%')

        Row() {
          HomeOptionCard({
            title: $r('app.string.home_toolbar'),
            subtitle: $r('app.string.home_toolbar_desc'),
            symbol: $r('sys.symbol.menubar_rectangle'),
            onPress: () => {
              this.pushPage(ROUTE_TOOLBAR);
            }
          })
          HomeOptionCard({
            title: $r('app.string.home_assist_input'),
            subtitle: $r('app.string.home_assist_input_desc'),
            symbol: $r('sys.symbol.keyboard_badge_spell'),
            onPress: () => {
              this.pushPage(ROUTE_ASSIST_INPUT);
            }
          })
        }
        .width('100%')

        Row() {
          HomeOptionCard({
            title: $r('app.string.home_keyboard_manage'),
            subtitle: $r('app.string.home_keyboard_manage_desc'),
            symbol: $r('sys.symbol.keyboard_badge_gearshape'),
            onPress: () => {
              this.pushPage(ROUTE_KEYBOARD_MANAGE);
            }
          })
          HomeOptionCard({
            title: $r('app.string.home_speech_text'),
            subtitle: $r('app.string.home_speech_text_desc'),
            symbol: $r('sys.symbol.mic_badge_gearshape'),
            onPress: () => {
              this.pushPage(ROUTE_SPEECH_TEXT);
            }
          })
        }
        .width('100%')

        Row() {
          HomeOptionCard({
            title: $r('app.string.home_system_material'),
            subtitle: $r('app.string.home_system_material_desc'),
            symbol: $r('sys.symbol.liquefying_clockwise'),
            onPress: () => {
              this.pushPage(ROUTE_SYSTEM_MATERIAL);
            }
          })
          HomeOptionCard({
            title: $r('app.string.panel_skin'),
            subtitle: $r('app.string.detail_toolbar_skin_desc'),
            symbol: $r('sys.symbol.shirt'),
            onPress: () => {
              this.pushPage(ROUTE_SKIN);
            }
          })
        }
        .width('100%')

        SectionTitle({ title: $r('app.string.home_section_more') })
        Row() {
          MoreOptionCard({
            title: $r('app.string.home_about'),
            symbol: $r('sys.symbol.info_circle'),
            onPress: () => {
              this.pushPage(ROUTE_ABOUT);
            }
          })
          MoreOptionCard({
            title: $r('app.string.home_help'),
            symbol: $r('sys.symbol.questionmark_circle'),
            onPress: () => {
              this.pushPage(ROUTE_HELP);
            }
          })
        }
        .width('100%')
        Blank().height(32)
      }
      .width('100%')
      .padding({ left: 14, right: 14 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private NavigationBuilder(name: string): void {
    SettingsDetailPage({ pageName: name })
  }

  build() {
    HdsNavigation(this.pageStack) {
      this.HomeContent()
    }
    .mode(NavigationMode.Stack)
    .titleMode(HdsNavigationTitleMode.MINI)
    .hideBackButton(true)
    .bindToScrollable([this.scroller])
    .navDestination(this.NavigationBuilder)
    .backgroundColor($r('app.color.settings_background'))
  }
}

@Component
struct SettingsDetailPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('topRectHeight') topRectHeight: number = 0;
  @StorageLink('ime.layoutMode') layoutMode: number = KeyboardLayoutMode.QWERTY26;
  @StorageLink('ime.keyboardHeightPercent') keyboardHeightPercent: number = 32;
  @StorageLink('ime.keyboardDockMode') keyboardDockMode: number = KeyboardDockMode.FULL;
  @StorageLink('ime.numberRow') numberRow: boolean = true;
  @StorageLink('ime.enterSend') enterSend: boolean = false;
  @StorageLink('ime.swapLangNumber') swapLangNumber: boolean = false;
  @StorageLink('ime.swipeInput') swipeInput: boolean = false;
  @StorageLink('ime.upperCase') upperCase: boolean = false;
  @StorageLink('ime.hapticStrength') hapticStrength: number = 45;
  @StorageLink('ime.soundVolume') soundVolume: number = 0;
  @StorageLink('ime.soundEffect') soundEffect: boolean = false;
  @StorageLink('ime.keyPopup') keyPopup: boolean = true;
  @StorageLink('ime.keyFontScale') keyFontScale: number = 100;
  @StorageLink('ime.longPressDelay') longPressDelay: number = 420;
  @StorageLink('ime.speechInput') speechInputEnabled: boolean = false;
  @StorageLink('ime.fuzzyPinyin') fuzzyPinyin: boolean = false;
  @StorageLink('ime.mixedInput') mixedInput: boolean = true;
  @StorageLink('ime.singleCharPriority') singleCharPriority: boolean = true;
  @StorageLink('ime.traditionalInput') traditionalInput: boolean = false;
  @StorageLink('ime.systemMaterialEnabled') systemMaterialEnabled: boolean = true;
  @StorageLink('ime.systemMaterialLevel') systemMaterialLevel: number = SystemMaterialLevelMode.REGULAR;
  @StorageLink('ime.skinPreset') skinPreset: number = KeyboardSkinPresetMode.LIQUID;
  @StorageLink('ime.skinBackgroundMode') skinBackgroundMode: number = KeyboardSkinBackgroundMode.COLOR;
  @StorageLink('ime.skinBackgroundColor') skinBackgroundColor: string = '#FFF1F4F9';
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';
  @StorageLink('ime.skinImageUri') skinImageUri: string = '';
  @StorageLink('ime.skinImagePath') skinImagePath: string = '';
  @StorageLink('ime.skinImageArea') skinImageArea: number = KeyboardSkinImageAreaMode.CENTER;
  @StorageLink('ime.skinImageBlur') skinImageBlur: number = 0;
  @State private pickingImage: boolean = false;
  @State private skinKeyboardTestText: string = '';
  @State private recentWordCount: number = SettingsStore.getRecentWordCount();
  @State private clipboardPermissionGranted: boolean = false;
  @State private feedbackText: string = '';
  pageName: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.refreshClipboardPermission();
  }

  private topInset(): number {
    return this.getUIContext().px2vp(this.topRectHeight) + 56;
  }

  private pageTitle(): ResourceStr {
    if (this.pageName === ROUTE_LAYOUT_DISPLAY) {
      return $r('app.string.home_layout_display');
    }
    if (this.pageName === ROUTE_KEY_EFFECT) {
      return $r('app.string.home_key_effect');
    }
    if (this.pageName === ROUTE_TOOLBAR) {
      return $r('app.string.home_toolbar');
    }
    if (this.pageName === ROUTE_ASSIST_INPUT) {
      return $r('app.string.home_assist_input');
    }
    if (this.pageName === ROUTE_KEYBOARD_MANAGE) {
      return $r('app.string.home_keyboard_manage');
    }
    if (this.pageName === ROUTE_SPEECH_TEXT) {
      return $r('app.string.home_speech_text');
    }
    if (this.pageName === ROUTE_SKIN) {
      return $r('app.string.skin_editor_title');
    }
    if (this.pageName === ROUTE_DICTIONARY) {
      return $r('app.string.dictionary_title');
    }
    if (this.pageName === ROUTE_SYSTEM_MATERIAL) {
      return $r('app.string.home_system_material');
    }
    if (this.pageName === ROUTE_ABOUT) {
      return $r('app.string.home_about');
    }
    if (this.pageName === ROUTE_HELP) {
      return $r('app.string.home_help');
    }
    return $r('app.string.settings_title');
  }

  private titleBarOptions(): HdsNavigationTitleBarOptions {
    let title: HdsTitleConfig = new HdsTitleConfig();
    title.mainTitle = this.pageTitle();

    let content: HdsTitleBarContentConfig = new HdsTitleBarContentConfig();
    content.title = title;

    let options: HdsTitleBarOptionsConfig = new HdsTitleBarOptionsConfig();
    options.content = content;
    options.style = HdsMaterialStyle.titleBarStyle(this.systemMaterialEnabled, this.systemMaterialLevel);
    return options;
  }

  private setLayoutMode(mode: number): void {
    this.layoutMode = mode;
    SettingsStore.updateLayoutMode(mode);
  }

  private clearDictionaryLearning(): void {
    SettingsStore.clearRecentWords();
    this.recentWordCount = SettingsStore.getRecentWordCount();
    promptAction.showToast({
      message: $r('app.string.dictionary_learning_cleared')
    });
  }

  private confirmClearDictionaryLearning(): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.dictionary_clear_confirm_title'),
      message: $r('app.string.dictionary_clear_confirm_message'),
      autoCancel: true,
      primaryButton: {
        value: $r('app.string.dictionary_cancel'),
        action: () => {}
      },
      secondaryButton: {
        value: $r('app.string.dictionary_clear_action'),
        fontColor: $r('app.color.danger'),
        action: () => {
          this.clearDictionaryLearning();
        }
      }
    });
  }

  private setKeyboardHeightPercent(value: number): void {
    this.keyboardHeightPercent = value;
    SettingsStore.updateNumber(SettingsStore.settingsKeyKeyboardHeightPercent(), value);
  }

  private setKeyboardDockMode(mode: number): void {
    this.keyboardDockMode = mode;
    SettingsStore.updateNumber(SettingsStore.settingsKeyKeyboardDockMode(), mode);
  }

  private setKeyFontScale(value: number): void {
    this.keyFontScale = value;
    SettingsStore.updateNumber(SettingsStore.settingsKeyKeyFontScale(), value);
  }

  private updateBoolean(key: string, value: boolean): void {
    SettingsStore.updateBoolean(key, value);
  }

  private updateNumber(key: string, value: number): void {
    SettingsStore.updateNumber(key, value);
  }

  private setSpeechInputEnabled(enabled: boolean): void {
    if (!enabled) {
      this.speechInputEnabled = false;
      SettingsStore.updateBoolean(SettingsStore.settingsKeySpeechInput(), false);
      return;
    }
    this.speechInputEnabled = true;
    let context: common.Context = getContext(this);
    abilityAccessCtrl.createAtManager()
      .requestPermissionsFromUser(context, ['ohos.permission.MICROPHONE'])
      .then((result: PermissionRequestResult): void => {
        let granted: boolean = result.authResults.length > 0 && result.authResults[0] === 0;
        this.speechInputEnabled = granted;
        SettingsStore.updateBoolean(SettingsStore.settingsKeySpeechInput(), granted);
        if (!granted) {
          promptAction.showToast({
            message: $r('app.string.voice_permission_denied')
          });
        }
      })
      .catch((err: BusinessError): void => {
        this.speechInputEnabled = false;
        SettingsStore.updateBoolean(SettingsStore.settingsKeySpeechInput(), false);
        hilog.error(0x0000, TAG, 'request microphone permission failed: %{public}d %{public}s', err.code, err.message);
        promptAction.showToast({
          message: $r('app.string.voice_permission_denied')
        });
      });
  }

  private async refreshClipboardPermission(): Promise<void> {
    try {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let status: abilityAccessCtrl.GrantStatus = await abilityAccessCtrl.createAtManager()
        .checkAccessToken(bundleInfo.appInfo.accessTokenId, READ_PASTEBOARD_PERMISSION);
      this.clipboardPermissionGranted = status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      this.clipboardPermissionGranted = false;
      hilog.error(0x0000, TAG, 'check clipboard permission failed: %{public}d %{public}s', err.code, err.message);
    }
  }

  private requestClipboardPermission(): void {
    let context: common.Context = getContext(this);
    abilityAccessCtrl.createAtManager()
      .requestPermissionsFromUser(context, [READ_PASTEBOARD_PERMISSION])
      .then((result: PermissionRequestResult): void => {
        let granted: boolean = result.authResults.length > 0 && result.authResults[0] === 0;
        this.clipboardPermissionGranted = granted;
        promptAction.showToast({
          message: granted ? $r('app.string.clipboard_permission_granted') :
            $r('app.string.clipboard_permission_denied')
        });
      })
      .catch((err: BusinessError): void => {
        this.clipboardPermissionGranted = false;
        hilog.error(0x0000, TAG, 'request clipboard permission failed: %{public}d %{public}s', err.code, err.message);
        promptAction.showToast({
          message: $r('app.string.clipboard_permission_denied')
        });
      });
  }

  private openInputMethodSettings(): void {
    inputMethod.getSetting().showOptionalInputMethods().then((shown: boolean): void => {
      if (!shown) {
        promptAction.showToast({
          message: $r('app.string.input_method_required_open_failed')
        });
      }
    }).catch((err: BusinessError): void => {
      hilog.error(0x0000, TAG, 'show optional input methods failed: %{public}d %{public}s', err.code, err.message);
      promptAction.showToast({
        message: $r('app.string.input_method_required_open_failed')
      });
    });
  }

  private resourceText(resource: Resource): string {
    try {
      let context: common.Context = getContext(this);
      return context.resourceManager.getStringSync(resource.id);
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'read localized feedback text failed: %{public}d %{public}s', err.code, err.message);
      return '';
    }
  }

  private buildFeedbackReport(): string {
    let description: string = this.feedbackText.trim();
    if (description.length === 0) {
      return '';
    }
    let title: string = this.resourceText($r('app.string.feedback_report_title'));
    let contentLabel: string = this.resourceText($r('app.string.feedback_report_content'));
    let appLabel: string = this.resourceText($r('app.string.feedback_report_app'));
    let versionLabel: string = this.resourceText($r('app.string.feedback_report_version'));
    let appName: string = this.resourceText($r('app.string.settings_title'));
    let version: string = this.resourceText($r('app.string.detail_about_version'));
    return title + '\n\n' + contentLabel + ':\n' + description + '\n\n' + appLabel + ': ' + appName + '\n' +
      versionLabel + ': ' + version;
  }

  private copyFeedbackReport(report: string, successMessage: Resource): void {
    let data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, report);
    pasteboard.getSystemPasteboard().setData(data).then((): void => {
      promptAction.showToast({
        message: successMessage
      });
    }).catch((err: BusinessError): void => {
      hilog.error(0x0000, TAG, 'copy feedback report failed: %{public}d %{public}s', err.code, err.message);
      promptAction.showToast({
        message: $r('app.string.feedback_copy_failed')
      });
    });
  }

  private copyFeedback(): void {
    let report: string = this.buildFeedbackReport();
    if (report.length === 0) {
      promptAction.showToast({
        message: $r('app.string.feedback_empty')
      });
      return;
    }
    this.copyFeedbackReport(report, $r('app.string.feedback_copied'));
  }

  private shareFeedback(): void {
    let report: string = this.buildFeedbackReport();
    if (report.length === 0) {
      promptAction.showToast({
        message: $r('app.string.feedback_empty')
      });
      return;
    }
    if (!canIUse('SystemCapability.Collaboration.SystemShare')) {
      this.copyFeedbackReport(report, $r('app.string.feedback_share_fallback'));
      return;
    }
    try {
      let record: systemShare.SharedRecord = {
        utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
        content: report,
        title: this.resourceText($r('app.string.feedback_report_title')),
        description: this.resourceText($r('app.string.detail_help_feedback_desc'))
      };
      let data: systemShare.SharedData = new systemShare.SharedData(record);
      let controller: systemShare.ShareController = new systemShare.ShareController(data);
      let options: systemShare.ShareControllerOptions = {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL
      };
      let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      controller.show(context, options).catch((err: BusinessError): void => {
        hilog.error(0x0000, TAG, 'show feedback share panel failed: %{public}d %{public}s', err.code, err.message);
        this.copyFeedbackReport(report, $r('app.string.feedback_share_fallback'));
      });
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'create feedback share data failed: %{public}d %{public}s', err.code, err.message);
      this.copyFeedbackReport(report, $r('app.string.feedback_share_fallback'));
    }
  }

  private setMaterialLevel(level: number): void {
    this.systemMaterialLevel = level;
    SettingsStore.updateNumber(SettingsStore.settingsKeySystemMaterialLevel(), level);
  }

  private applySkinPreset(preset: number): void {
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

  private setSkinBackgroundColor(color: string): void {
    this.skinPreset = KeyboardSkinPresetMode.CUSTOM;
    this.skinBackgroundMode = KeyboardSkinBackgroundMode.COLOR;
    this.skinBackgroundColor = color;
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinPreset(), KeyboardSkinPresetMode.CUSTOM);
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinBackgroundMode(), KeyboardSkinBackgroundMode.COLOR);
    SettingsStore.updateString(SettingsStore.settingsKeySkinBackgroundColor(), color);
  }

  private setSkinKeyColor(color: string): void {
    this.skinPreset = KeyboardSkinPresetMode.CUSTOM;
    this.skinKeyColor = color;
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinPreset(), KeyboardSkinPresetMode.CUSTOM);
    SettingsStore.updateString(SettingsStore.settingsKeySkinKeyColor(), color);
  }

  private setSkinImageArea(area: number): void {
    this.skinImageArea = area;
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinImageArea(), area);
  }

  private setSkinImageBlur(value: number): void {
    this.skinImageBlur = value;
    SettingsStore.updateNumber(SettingsStore.settingsKeySkinImageBlur(), value);
  }

  private clearSkinImage(): void {
    this.skinImageUri = '';
    this.skinImagePath = '';
    this.skinBackgroundMode = KeyboardSkinBackgroundMode.COLOR;
    SettingsStore.clearSkinImage();
  }

  private async buildKeyboardSkinImageData(sourceUri: string): Promise<Uint8Array> {
    let sourceFile: fileIo.File | undefined = undefined;
    let imageSource: image.ImageSource | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;
    let imagePacker: image.ImagePacker | undefined = undefined;
    try {
      sourceFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY);
      imageSource = image.createImageSource(sourceFile.fd);
      let targetSize: image.Size = {
        width: SKIN_IMAGE_TARGET_WIDTH,
        height: SKIN_IMAGE_TARGET_HEIGHT
      };
      let decodingOptions: image.DecodingOptions = {
        desiredSize: targetSize
      };
      pixelMap = imageSource.createPixelMapSync(decodingOptions);
      imagePacker = image.createImagePacker();
      let packingOptions: image.PackingOption = {
        format: 'image/jpeg',
        quality: SKIN_IMAGE_PACK_QUALITY,
        bufferSize: SKIN_IMAGE_PACK_BUFFER_SIZE
      };
      let packedData: ArrayBuffer = await imagePacker.packToData(pixelMap, packingOptions);
      return new Uint8Array(packedData);
    } finally {
      if (imagePacker !== undefined) {
        imagePacker.release();
      }
      if (pixelMap !== undefined) {
        pixelMap.release();
      }
      if (imageSource !== undefined) {
        imageSource.release();
      }
      if (sourceFile !== undefined) {
        fileIo.closeSync(sourceFile);
      }
    }
  }

  private async persistSkinImage(sourceUri: string): Promise<StoredSkinImage> {
    let result: StoredSkinImage = new StoredSkinImage();
    result.path = '';
    result.uri = sourceUri;
    result.data = await this.buildKeyboardSkinImageData(sourceUri);
    return result;
  }

  private async selectSkinImage(): Promise<void> {
    if (this.pickingImage) {
      return;
    }
    this.pickingImage = true;
    try {
      let photoSelectOptions: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      let result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(photoSelectOptions);
      if (result.photoUris.length > 0) {
        let uri: string = result.photoUris[0];
        let storedImage: StoredSkinImage = await this.persistSkinImage(uri);
        SettingsStore.applySkinImage(storedImage.uri, storedImage.path, storedImage.data);
        let appliedSettings: ImeSettings = SettingsStore.getSettings();
        this.skinPreset = appliedSettings.skinPreset;
        this.skinBackgroundMode = appliedSettings.skinBackgroundMode;
        this.skinKeyColor = appliedSettings.skinKeyColor;
        this.skinImageUri = appliedSettings.skinImageUri;
        this.skinImagePath = appliedSettings.skinImagePath;
        this.skinImageBlur = appliedSettings.skinImageBlur;
      }
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'select skin image failed: %{public}d %{public}s', err.code, err.message);
      promptAction.showToast({
        message: $r('app.string.skin_image_apply_failed')
      });
    } finally {
      this.pickingImage = false;
    }
  }

  @Builder
  private DetailContent(): void {
    Scroll(this.scroller) {
      Column() {
        Blank()
          .height(this.topInset() + 12)
          .width('100%')
        if (this.pageName === ROUTE_LAYOUT_DISPLAY) {
          this.LayoutDisplayContent()
        } else if (this.pageName === ROUTE_KEY_EFFECT) {
          this.KeyEffectContent()
        } else if (this.pageName === ROUTE_TOOLBAR) {
          this.ToolbarContent()
        } else if (this.pageName === ROUTE_ASSIST_INPUT) {
          this.AssistInputContent()
        } else if (this.pageName === ROUTE_KEYBOARD_MANAGE) {
          this.KeyboardManageContent()
        } else if (this.pageName === ROUTE_SPEECH_TEXT) {
          this.SpeechTextContent()
        } else if (this.pageName === ROUTE_SKIN) {
          this.SkinContent()
        } else if (this.pageName === ROUTE_DICTIONARY) {
          this.DictionaryContent()
        } else if (this.pageName === ROUTE_SYSTEM_MATERIAL) {
          this.SystemMaterialContent()
        } else if (this.pageName === ROUTE_ABOUT) {
          this.AboutContent()
        } else {
          this.HelpContent()
        }
        Blank().height(32)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private LayoutDisplayContent(): void {
    SectionTitle({ title: $r('app.string.detail_layout_keyboard_title') })
    Row() {
      ChoiceCard({
        title: $r('app.string.layout_26'),
        subtitle: $r('app.string.detail_layout_26_desc'),
        symbol: $r('sys.symbol.keyboard_badge_26'),
        selected: this.layoutMode === KeyboardLayoutMode.QWERTY26,
        onPress: () => {
          this.setLayoutMode(KeyboardLayoutMode.QWERTY26);
        }
      })
      ChoiceCard({
        title: $r('app.string.layout_9'),
        subtitle: $r('app.string.detail_layout_9_desc'),
        symbol: $r('sys.symbol.keyboard_badge_9'),
        selected: this.layoutMode === KeyboardLayoutMode.T9,
        onPress: () => {
          this.setLayoutMode(KeyboardLayoutMode.T9);
        }
      })
    }
    .width('100%')
    Row() {
      ChoiceCard({
        title: $r('app.string.panel_double_pinyin'),
        subtitle: $r('app.string.detail_layout_shuangpin_desc'),
        symbol: $r('sys.symbol.keyboard_badge_spell'),
        selected: this.layoutMode === KeyboardLayoutMode.XIAOHE_SHUANGPIN,
        onPress: () => {
          this.setLayoutMode(KeyboardLayoutMode.XIAOHE_SHUANGPIN);
        }
      })
    }
    .width('100%')

    PreferenceSlider({
      title: $r('app.string.keyboard_height'),
      value: this.keyboardHeightPercent,
      min: 24,
      max: 42,
      unit: '%',
      onChange: (value: number) => {
        this.setKeyboardHeightPercent(value);
      }
    })
    PreferenceSlider({
      title: $r('app.string.panel_font_size'),
      value: this.keyFontScale,
      min: 90,
      max: 120,
      unit: '%',
      onChange: (value: number) => {
        this.setKeyFontScale(value);
      }
    })
    PreferenceSwitch({
      title: $r('app.string.number_row'),
      subtitle: $r('app.string.detail_number_row_desc'),
      value: this.numberRow,
      onChange: (value: boolean) => {
        this.numberRow = value;
        this.updateBoolean(SettingsStore.settingsKeyNumberRow(), value);
      }
    })
    PreferenceSwitch({
      title: $r('app.string.swipe_input'),
      subtitle: $r('app.string.detail_swipe_input_desc'),
      value: this.swipeInput,
      onChange: (value: boolean) => {
        this.swipeInput = value;
        this.updateBoolean(SettingsStore.settingsKeySwipeInput(), value);
      }
    })
    PreferenceSwitch({
      title: $r('app.string.swap_lang_number'),
      subtitle: $r('app.string.detail_swap_lang_number_desc'),
      value: this.swapLangNumber,
      onChange: (value: boolean) => {
        this.swapLangNumber = value;
        this.updateBoolean(SettingsStore.settingsKeySwapLangNumber(), value);
      }
    })
    PreferenceSwitch({
      title: $r('app.string.upper_case'),
      subtitle: $r('app.string.detail_upper_case_desc'),
      value: this.upperCase,
      onChange: (value: boolean) => {
        this.upperCase = value;
        this.updateBoolean(SettingsStore.settingsKeyUpperCase(), value);
      }
    })
  }

  @Builder
  private KeyEffectContent(): void {
    SectionTitle({ title: $r('app.string.detail_key_audio_title') })
    PreferenceSwitch({
      title: $r('app.string.sound_effect'),
      subtitle: $r('app.string.detail_sound_effect_desc'),
      value: this.soundEffect,
      onChange: (value: boolean) => {
        this.soundEffect = value;
        this.updateBoolean(SettingsStore.settingsKeySoundEffect(), value);
      }
    })
    PreferenceSlider({
      title: $r('app.string.sound_volume'),
      value: this.soundVolume,
      min: 0,
      max: 100,
      unit: '%',
      onChange: (value: number) => {
        this.soundVolume = value;
        this.updateNumber(SettingsStore.settingsKeySoundVolume(), value);
      }
    })
    PreferenceSlider({
      title: $r('app.string.haptic_strength'),
      value: this.hapticStrength,
      min: 0,
      max: 100,
      unit: '%',
      onChange: (value: number) => {
        this.hapticStrength = value;
        this.updateNumber(SettingsStore.settingsKeyHapticStrength(), value);
      }
    })
    PreferenceSwitch({
      title: $r('app.string.key_popup'),
      subtitle: $r('app.string.detail_key_popup_desc'),
      value: this.keyPopup,
      onChange: (value: boolean) => {
        this.keyPopup = value;
        this.updateBoolean(SettingsStore.settingsKeyKeyPopup(), value);
      }
    })
    PreferenceSlider({
      title: $r('app.string.long_press_delay'),
      value: this.longPressDelay,
      min: 250,
      max: 800,
      unit: 'ms',
      onChange: (value: number) => {
        this.longPressDelay = value;
        this.updateNumber(SettingsStore.settingsKeyLongPressDelay(), value);
      }
    })
  }

  @Builder
  private ToolbarContent(): void {
    SectionTitle({ title: $r('app.string.detail_toolbar_title') })
    InfoOptionRow({
      title: $r('app.string.detail_toolbar_fold'),
      subtitle: $r('app.string.detail_toolbar_fold_desc'),
      symbol: $r('sys.symbol.menubar_rectangle'),
      enabledText: $r('app.string.enabled'),
      hasEnabledText: true
    })
    InfoOptionRow({
      title: $r('app.string.detail_toolbar_fixed'),
      subtitle: $r('app.string.detail_toolbar_fixed_desc'),
      symbol: $r('sys.symbol.square_grid_2x2_checkmark_topleft_fill'),
      enabledText: $r('app.string.enabled'),
      hasEnabledText: true
    })
    InfoOptionRow({
      title: $r('app.string.detail_toolbar_skin'),
      subtitle: $r('app.string.detail_toolbar_skin_desc'),
      symbol: $r('sys.symbol.paintbrush_pointed_drop'),
      enabledText: $r('app.string.enabled'),
      hasEnabledText: true
    })
    if (this.clipboardPermissionGranted) {
      InfoOptionRow({
        title: $r('app.string.clipboard_permission_title'),
        subtitle: $r('app.string.clipboard_permission_desc'),
        symbol: $r('sys.symbol.text_clipboard'),
        enabledText: $r('app.string.clipboard_permission_enabled'),
        hasEnabledText: true
      })
    } else {
      ActionOptionRow({
        title: $r('app.string.clipboard_permission_title'),
        subtitle: $r('app.string.clipboard_permission_desc'),
        symbol: $r('sys.symbol.text_clipboard'),
        onPress: (): void => {
          this.requestClipboardPermission();
        }
      })
    }
  }

  @Builder
  private AssistInputContent(): void {
    SectionTitle({ title: $r('app.string.detail_assist_title') })
    PreferenceSwitch({
      title: $r('app.string.enter_send'),
      subtitle: $r('app.string.detail_enter_send_desc'),
      value: this.enterSend,
      onChange: (value: boolean) => {
        this.enterSend = value;
        this.updateBoolean(SettingsStore.settingsKeyEnterSend(), value);
      }
    })
    PreferenceSwitch({
      title: $r('app.string.mixed_input'),
      subtitle: $r('app.string.detail_mixed_input_desc'),
      value: this.mixedInput,
      onChange: (value: boolean) => {
        this.mixedInput = value;
        this.updateBoolean(SettingsStore.settingsKeyMixedInput(), value);
        pinyinEngine.refreshForSettings();
      }
    })
    PreferenceSwitch({
      title: $r('app.string.single_char_priority'),
      subtitle: $r('app.string.detail_single_char_priority_desc'),
      value: this.singleCharPriority,
      onChange: (value: boolean) => {
        this.singleCharPriority = value;
        this.updateBoolean(SettingsStore.settingsKeySingleCharPriority(), value);
        pinyinEngine.refreshForSettings();
      }
    })
    PreferenceSwitch({
      title: $r('app.string.fuzzy_pinyin'),
      subtitle: $r('app.string.detail_fuzzy_pinyin_desc'),
      value: this.fuzzyPinyin,
      onChange: (value: boolean) => {
        this.fuzzyPinyin = value;
        this.updateBoolean(SettingsStore.settingsKeyFuzzyPinyin(), value);
        pinyinEngine.refreshForSettings();
      }
    })
    PreferenceSwitch({
      title: $r('app.string.traditional_input'),
      subtitle: $r('app.string.detail_traditional_desc'),
      value: this.traditionalInput,
      onChange: (value: boolean) => {
        this.traditionalInput = value;
        this.updateBoolean(SettingsStore.settingsKeyTraditional(), value);
        pinyinEngine.refreshForSettings();
      }
    })
  }

  @Builder
  private KeyboardManageContent(): void {
    SectionTitle({ title: $r('app.string.detail_keyboard_main_title') })
    Row() {
      ChoiceCard({
        title: $r('app.string.layout_26'),
        subtitle: $r('app.string.detail_layout_26_desc'),
        symbol: $r('sys.symbol.keyboard_badge_26'),
        selected: this.layoutMode === KeyboardLayoutMode.QWERTY26,
        onPress: () => {
          this.setLayoutMode(KeyboardLayoutMode.QWERTY26);
        }
      })
      ChoiceCard({
        title: $r('app.string.layout_9'),
        subtitle: $r('app.string.detail_layout_9_desc'),
        symbol: $r('sys.symbol.keyboard_badge_9'),
        selected: this.layoutMode === KeyboardLayoutMode.T9,
        onPress: () => {
          this.setLayoutMode(KeyboardLayoutMode.T9);
        }
      })
    }
    .width('100%')
    Row() {
      ChoiceCard({
        title: $r('app.string.panel_double_pinyin'),
        subtitle: $r('app.string.detail_layout_shuangpin_desc'),
        symbol: $r('sys.symbol.keyboard_badge_spell'),
        selected: this.layoutMode === KeyboardLayoutMode.XIAOHE_SHUANGPIN,
        onPress: () => {
          this.setLayoutMode(KeyboardLayoutMode.XIAOHE_SHUANGPIN);
        }
      })
    }
    .width('100%')
    SectionTitle({ title: $r('app.string.panel_keyboard_move') })
    Row() {
      ChoiceCard({
        title: $r('app.string.panel_full_keyboard'),
        subtitle: $r('app.string.detail_dock_full_desc'),
        symbol: $r('sys.symbol.keyboard_badge_full'),
        selected: this.keyboardDockMode === KeyboardDockMode.FULL,
        onPress: () => {
          this.setKeyboardDockMode(KeyboardDockMode.FULL);
        }
      })
      ChoiceCard({
        title: $r('app.string.panel_onehand_left'),
        subtitle: $r('app.string.detail_dock_left_desc'),
        symbol: $r('sys.symbol.keyboard_onehanded_left'),
        selected: this.keyboardDockMode === KeyboardDockMode.LEFT,
        onPress: () => {
          this.setKeyboardDockMode(KeyboardDockMode.LEFT);
        }
      })
    }
    .width('100%')
    Row() {
      ChoiceCard({
        title: $r('app.string.panel_onehand_right'),
        subtitle: $r('app.string.detail_dock_right_desc'),
        symbol: $r('sys.symbol.keyboard_onehanded_right'),
        selected: this.keyboardDockMode === KeyboardDockMode.RIGHT,
        onPress: () => {
          this.setKeyboardDockMode(KeyboardDockMode.RIGHT);
        }
      })
    }
    .width('100%')
  }

  @Builder
  private SpeechTextContent(): void {
    SectionTitle({ title: $r('app.string.detail_speech_title') })
    PreferenceSwitch({
      title: $r('app.string.detail_speech_space'),
      subtitle: $r('app.string.detail_speech_space_desc'),
      value: this.speechInputEnabled,
      onChange: (value: boolean) => {
        this.setSpeechInputEnabled(value);
      }
    })
    InfoOptionRow({
      title: $r('app.string.detail_speech_lang'),
      subtitle: $r('app.string.detail_speech_lang_desc'),
      symbol: $r('sys.symbol.text_speaker_wave_rectangle'),
      enabledText: $r('app.string.voice_language_follow_input'),
      hasEnabledText: true
    })
    InfoOptionRow({
      title: $r('app.string.voice_offline_title'),
      subtitle: $r('app.string.voice_offline_desc'),
      symbol: $r('sys.symbol.lock_shield'),
      enabledText: $r('app.string.voice_offline_badge'),
      hasEnabledText: true
    })
  }

  @Builder
  private SkinPreview(): void {
    Stack() {
      if (this.skinBackgroundMode === KeyboardSkinBackgroundMode.IMAGE && this.skinImageUri.length > 0) {
        Image(this.skinImageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(this.skinImageBlur)
      }
      Column() {
        Row() {
          Blank()
            .layoutWeight(1)
            .height(34)
            .borderRadius(12)
            .backgroundColor(this.skinKeyColor)
          Blank()
            .layoutWeight(1)
            .height(34)
            .borderRadius(12)
            .backgroundColor(this.skinKeyColor)
            .margin({ left: 8 })
          Blank()
            .layoutWeight(1)
            .height(34)
            .borderRadius(12)
            .backgroundColor(this.skinKeyColor)
            .margin({ left: 8 })
        }
        .width('100%')

        Row() {
          Blank()
            .layoutWeight(1)
            .height(34)
            .borderRadius(12)
            .backgroundColor(this.skinKeyColor)
          Blank()
            .layoutWeight(1)
            .height(34)
            .borderRadius(12)
            .backgroundColor(this.skinKeyColor)
            .margin({ left: 8 })
          Blank()
            .layoutWeight(1)
            .height(34)
            .borderRadius(12)
            .backgroundColor(this.skinKeyColor)
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 10 })
      }
      .width('100%')
      .padding(18)
    }
    .width('100%')
    .height(148)
    .margin({ top: 10 })
    .backgroundColor(this.skinBackgroundMode === KeyboardSkinBackgroundMode.IMAGE ? '#FF101824' :
      this.skinBackgroundColor)
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
  }

  @Builder
  private SkinKeyboardTest(): void {
    Column() {
      TextInput({ placeholder: $r('app.string.skin_keyboard_test_placeholder'), text: this.skinKeyboardTestText })
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontColor($r('app.color.key_text'))
        .placeholderColor($r('app.color.text_muted'))
        .caretColor($r('app.color.material_primary'))
        .backgroundColor($r('app.color.settings_icon_background'))
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.skinKeyboardTestText = value;
        })
    }
    .width('100%')
    .padding(14)
    .margin({ top: 10 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
  }

  @Builder
  private SkinContent(): void {
    SectionTitle({ title: $r('app.string.skin_editor_title') })
    this.SkinPreview()

    SectionTitle({ title: $r('app.string.skin_presets') })
    Row() {
      SettingsSkinPresetCard({
        title: $r('app.string.skin_preset_liquid'),
        backgroundColorValue: '#FFF1F4F9',
        keyColorValue: '#F2FFFFFF',
        selected: this.skinPreset === KeyboardSkinPresetMode.LIQUID,
        onPress: () => {
          this.applySkinPreset(KeyboardSkinPresetMode.LIQUID);
        }
      })
      SettingsSkinPresetCard({
        title: $r('app.string.skin_preset_mint'),
        backgroundColorValue: '#FFE8F7F4',
        keyColorValue: '#FFE8F7F4',
        selected: this.skinPreset === KeyboardSkinPresetMode.MINT,
        onPress: () => {
          this.applySkinPreset(KeyboardSkinPresetMode.MINT);
        }
      })
    }
    .width('100%')
    Row() {
      SettingsSkinPresetCard({
        title: $r('app.string.skin_preset_night'),
        backgroundColorValue: '#FF101824',
        keyColorValue: '#55FFFFFF',
        selected: this.skinPreset === KeyboardSkinPresetMode.NIGHT,
        onPress: () => {
          this.applySkinPreset(KeyboardSkinPresetMode.NIGHT);
        }
      })
      SettingsSkinPresetCard({
        title: $r('app.string.skin_preset_sunset'),
        backgroundColorValue: '#FFFFF1E7',
        keyColorValue: '#FFFFFAF2',
        selected: this.skinPreset === KeyboardSkinPresetMode.SUNSET,
        onPress: () => {
          this.applySkinPreset(KeyboardSkinPresetMode.SUNSET);
        }
      })
    }
    .width('100%')
    Row() {
      SettingsSkinPresetCard({
        title: $r('app.string.skin_preset_rainbow'),
        backgroundColorValue: '#FFF8F9FA',
        keyColorValue: '#FF9966FF',
        selected: this.skinPreset === KeyboardSkinPresetMode.RAINBOW,
        onPress: () => {
          this.applySkinPreset(KeyboardSkinPresetMode.RAINBOW);
        }
      })
      SettingsSkinPresetCard({
        title: $r('app.string.skin_preset_rainbow_text'),
        backgroundColorValue: '#FFF8F9FA',
        keyColorValue: '#F2FFFFFF',
        selected: this.skinPreset === KeyboardSkinPresetMode.RAINBOW_TEXT,
        onPress: () => {
          this.applySkinPreset(KeyboardSkinPresetMode.RAINBOW_TEXT);
        }
      })
    }
    .width('100%')

    SectionTitle({ title: $r('app.string.skin_background_color') })
    Row() {
      SettingsSkinColorSwatch({
        colorValue: '#FFF1F4F9',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFF1F4F9' &&
          this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
        onPress: () => {
          this.setSkinBackgroundColor('#FFF1F4F9');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#FFE8F7F4',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFE8F7F4' &&
          this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
        onPress: () => {
          this.setSkinBackgroundColor('#FFE8F7F4');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#FFFFF1E7',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFFFF1E7' &&
          this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
        onPress: () => {
          this.setSkinBackgroundColor('#FFFFF1E7');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#FFEEEAF8',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFEEEAF8' &&
          this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
        onPress: () => {
          this.setSkinBackgroundColor('#FFEEEAF8');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#FFFFF7D6',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FFFFF7D6' &&
          this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
        onPress: () => {
          this.setSkinBackgroundColor('#FFFFF7D6');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#FF101824',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinBackgroundColor === '#FF101824' &&
          this.skinBackgroundMode === KeyboardSkinBackgroundMode.COLOR,
        onPress: () => {
          this.setSkinBackgroundColor('#FF101824');
        }
      })
    }
    .width('100%')

    Row() {
      SettingsSkinActionButton({
        title: this.pickingImage ? $r('app.string.skin_image_picking') : $r('app.string.skin_choose_image'),
        symbol: $r('sys.symbol.ohos_photo'),
        enabledValue: !this.pickingImage,
        onPress: () => {
          this.selectSkinImage();
        }
      })
      SettingsSkinActionButton({
        title: $r('app.string.skin_clear_image'),
        symbol: $r('sys.symbol.trash'),
        enabledValue: this.skinImageUri.length > 0,
        onPress: () => {
          this.clearSkinImage();
        }
      })
    }
    .width('100%')

    SectionTitle({ title: $r('app.string.skin_keyboard_test') })
    this.SkinKeyboardTest()

    if (this.skinImageUri.length > 0) {
      SectionTitle({ title: $r('app.string.skin_image_area') })
      Row() {
        SettingsSkinAreaChip({
          title: $r('app.string.skin_area_center'),
          selected: this.skinImageArea === KeyboardSkinImageAreaMode.CENTER,
          onPress: () => {
            this.setSkinImageArea(KeyboardSkinImageAreaMode.CENTER);
          }
        })
        SettingsSkinAreaChip({
          title: $r('app.string.skin_area_top'),
          selected: this.skinImageArea === KeyboardSkinImageAreaMode.TOP,
          onPress: () => {
            this.setSkinImageArea(KeyboardSkinImageAreaMode.TOP);
          }
        })
        SettingsSkinAreaChip({
          title: $r('app.string.skin_area_bottom'),
          selected: this.skinImageArea === KeyboardSkinImageAreaMode.BOTTOM,
          onPress: () => {
            this.setSkinImageArea(KeyboardSkinImageAreaMode.BOTTOM);
          }
        })
        SettingsSkinAreaChip({
          title: $r('app.string.skin_area_left'),
          selected: this.skinImageArea === KeyboardSkinImageAreaMode.LEFT,
          onPress: () => {
            this.setSkinImageArea(KeyboardSkinImageAreaMode.LEFT);
          }
        })
        SettingsSkinAreaChip({
          title: $r('app.string.skin_area_right'),
          selected: this.skinImageArea === KeyboardSkinImageAreaMode.RIGHT,
          onPress: () => {
            this.setSkinImageArea(KeyboardSkinImageAreaMode.RIGHT);
          }
        })
      }
      .width('100%')

      PreferenceSlider({
        title: $r('app.string.skin_image_blur'),
        value: this.skinImageBlur,
        min: 0,
        max: 20,
        unit: '',
        onChange: (value: number) => {
          this.setSkinImageBlur(value);
        }
      })
    }

    SectionTitle({ title: $r('app.string.skin_key_color') })
    Row() {
      SettingsSkinColorSwatch({
        colorValue: '#F2FFFFFF',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#F2FFFFFF',
        onPress: () => {
          this.setSkinKeyColor('#F2FFFFFF');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#EFFFFFFF',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#EFFFFFFF',
        onPress: () => {
          this.setSkinKeyColor('#EFFFFFFF');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#FFFFFAF2',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#FFFFFAF2',
        onPress: () => {
          this.setSkinKeyColor('#FFFFFAF2');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#FFE8EEF8',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#FFE8EEF8',
        onPress: () => {
          this.setSkinKeyColor('#FFE8EEF8');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#FFFFE2D4',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#FFFFE2D4',
        onPress: () => {
          this.setSkinKeyColor('#FFFFE2D4');
        }
      })
      SettingsSkinColorSwatch({
        colorValue: '#55FFFFFF',
        selected: this.skinPreset === KeyboardSkinPresetMode.CUSTOM && this.skinKeyColor === '#55FFFFFF',
        onPress: () => {
          this.setSkinKeyColor('#55FFFFFF');
        }
      })
    }
    .width('100%')
  }

  @Builder
  private SystemMaterialContent(): void {
    SectionTitle({ title: $r('app.string.detail_material_title') })
    PreferenceSwitch({
      title: $r('app.string.system_material_enabled'),
      subtitle: $r('app.string.system_material_enabled_desc'),
      value: this.systemMaterialEnabled,
      onChange: (value: boolean) => {
        this.systemMaterialEnabled = value;
        this.updateBoolean(SettingsStore.settingsKeySystemMaterialEnabled(), value);
      }
    })
    InfoOptionRow({
      title: HdsMaterialStyle.isAvailable() ? $r('app.string.system_material_available') :
        $r('app.string.system_material_unavailable'),
      subtitle: HdsMaterialStyle.isImmersiveSupported() ? $r('app.string.system_material_immersive_supported') :
        $r('app.string.system_material_adaptive_supported'),
      symbol: $r('sys.symbol.liquefying_clockwise')
    })
    MaterialLevelCard({
      title: $r('app.string.material_level_ultra_thin'),
      subtitle: $r('app.string.material_level_ultra_thin_desc'),
      selected: this.systemMaterialLevel === SystemMaterialLevelMode.ULTRA_THIN,
      itemEnabled: this.systemMaterialEnabled,
      onPress: () => {
        this.setMaterialLevel(SystemMaterialLevelMode.ULTRA_THIN);
      }
    })
    MaterialLevelCard({
      title: $r('app.string.material_level_thin'),
      subtitle: $r('app.string.material_level_thin_desc'),
      selected: this.systemMaterialLevel === SystemMaterialLevelMode.THIN,
      itemEnabled: this.systemMaterialEnabled,
      onPress: () => {
        this.setMaterialLevel(SystemMaterialLevelMode.THIN);
      }
    })
    MaterialLevelCard({
      title: $r('app.string.material_level_regular'),
      subtitle: $r('app.string.material_level_regular_desc'),
      selected: this.systemMaterialLevel === SystemMaterialLevelMode.REGULAR,
      itemEnabled: this.systemMaterialEnabled,
      onPress: () => {
        this.setMaterialLevel(SystemMaterialLevelMode.REGULAR);
      }
    })
    MaterialLevelCard({
      title: $r('app.string.material_level_thick'),
      subtitle: $r('app.string.material_level_thick_desc'),
      selected: this.systemMaterialLevel === SystemMaterialLevelMode.THICK,
      itemEnabled: this.systemMaterialEnabled,
      onPress: () => {
        this.setMaterialLevel(SystemMaterialLevelMode.THICK);
      }
    })
    MaterialLevelCard({
      title: $r('app.string.material_level_ultra_thick'),
      subtitle: $r('app.string.material_level_ultra_thick_desc'),
      selected: this.systemMaterialLevel === SystemMaterialLevelMode.ULTRA_THICK,
      itemEnabled: this.systemMaterialEnabled,
      onPress: () => {
        this.setMaterialLevel(SystemMaterialLevelMode.ULTRA_THICK);
      }
    })
  }

  @Builder
  private AboutContent(): void {
    SectionTitle({ title: $r('app.string.detail_about_title') })
    InfoOptionRow({
      title: $r('app.string.settings_title'),
      subtitle: $r('app.string.ime_desc'),
      symbol: $r('sys.symbol.info_circle'),
      enabledText: $r('app.string.detail_about_version'),
      hasEnabledText: true
    })
    InfoOptionRow({
      title: $r('app.string.offline_engine'),
      subtitle: $r('app.string.candidate_hint'),
      symbol: $r('sys.symbol.keyboard_badge_spell'),
      enabledText: $r('app.string.enabled'),
      hasEnabledText: true
    })
  }

  @Builder
  private DictionaryContent(): void {
    SectionTitle({ title: $r('app.string.dictionary_title') })
    InfoOptionRow({
      title: $r('app.string.offline_engine'),
      subtitle: $r('app.string.dictionary_offline_desc'),
      symbol: $r('sys.symbol.keyboard_badge_spell'),
      enabledText: $r('app.string.enabled'),
      hasEnabledText: true
    })
    InfoOptionRow({
      title: $r('app.string.dictionary_learning_title'),
      subtitle: $r('app.string.dictionary_learning_desc'),
      symbol: $r('sys.symbol.clock'),
      enabledText: this.recentWordCount > 0 ? this.recentWordCount.toString() :
        $r('app.string.dictionary_learning_empty'),
      hasEnabledText: true
    })
    DestructiveOptionRow({
      title: $r('app.string.dictionary_clear_action'),
      subtitle: $r('app.string.dictionary_clear_desc'),
      itemEnabled: this.recentWordCount > 0,
      onPress: () => {
        this.confirmClearDictionaryLearning();
      }
    })
  }

  @Builder
  private HelpContent(): void {
    SectionTitle({ title: $r('app.string.detail_help_title') })
    ActionOptionRow({
      title: $r('app.string.detail_help_enable'),
      subtitle: $r('app.string.settings_hint'),
      symbol: $r('sys.symbol.keyboard'),
      onPress: () => {
        this.openInputMethodSettings();
      }
    })
    Column() {
      Row() {
        Stack() {
          SystemSymbolIcon({
            symbol: $r('sys.symbol.text_badge_questionmark'),
            color: $r('app.color.text_secondary'),
            iconSize: 24
          })
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor($r('app.color.settings_icon_background'))

        Column() {
          Text($r('app.string.detail_help_feedback'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.key_text'))
          Text($r('app.string.detail_help_feedback_desc'))
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
            .lineHeight(19)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      TextArea({
        placeholder: $r('app.string.feedback_placeholder'),
        text: this.feedbackText
      })
        .width('100%')
        .height(132)
        .fontSize(15)
        .fontColor($r('app.color.key_text'))
        .placeholderColor($r('app.color.text_muted'))
        .caretColor($r('app.color.material_primary'))
        .padding(12)
        .margin({ top: 14 })
        .backgroundColor($r('app.color.settings_icon_background'))
        .borderRadius(14)
        .maxLength(1000)
        .onChange((value: string): void => {
          this.feedbackText = value;
        })

      Row() {
        SettingsSkinActionButton({
          title: $r('app.string.feedback_copy_action'),
          symbol: $r('sys.symbol.text_clipboard'),
          enabledValue: this.feedbackText.trim().length > 0,
          onPress: () => {
            this.copyFeedback();
          }
        })
        SettingsSkinActionButton({
          title: $r('app.string.feedback_share_action'),
          symbol: $r('sys.symbol.share'),
          enabledValue: this.feedbackText.trim().length > 0,
          onPress: () => {
            this.shareFeedback();
          }
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .margin({ top: 10 })
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(18)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
  }

  build() {
    HdsNavDestination() {
      this.DetailContent()
    }
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .hideBackButton(false)
    .onBackPressed(() => {
      this.pageStack.pop();
      return true;
    })
    .bindToScrollable([this.scroller])
    .titleBar(this.titleBarOptions())
    .backgroundColor($r('app.color.settings_background'))
  }
}
