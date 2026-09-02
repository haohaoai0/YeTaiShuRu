import { promptAction, router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { inputMethod } from '@kit.IMEKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LiquidMaterial } from '../common/LiquidMaterial';
import { InputMethodStatus } from '../model/InputMethodStatus';

const TAG: string = 'InputMethodRequired';

@Entry
@Component
struct InputMethodRequired {
  @StorageLink('topRectHeight') topRectHeight: number = 0;

  private topInset(): number {
    return this.getUIContext().px2vp(this.topRectHeight) + 18;
  }

  private openInputMethodSettings(): void {
    inputMethod.getSetting().showOptionalInputMethods().then((shown: boolean) => {
      if (!shown) {
        promptAction.showToast({
          message: $r('app.string.input_method_required_open_failed')
        });
      }
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'showOptionalInputMethods failed: %{public}d %{public}s', err.code, err.message);
      promptAction.showToast({
        message: $r('app.string.input_method_required_open_failed')
      });
    });
  }

  private recheckInputMethod(): void {
    if (!InputMethodStatus.isLiquidImeCurrent()) {
      promptAction.showToast({
        message: $r('app.string.input_method_required_toast')
      });
      return;
    }
    router.replaceUrl({ url: 'pages/Index' }).then(() => {
      hilog.info(0x0000, TAG, 'entered settings home');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'replace home failed: %{public}d %{public}s', err.code, err.message);
    });
  }

  @Builder
  private PrimaryButton(): void {
    Button({ type: ButtonType.Capsule, stateEffect: true }) {
      Text($r('app.string.input_method_required_action'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(50)
    .backgroundColor($r('app.color.material_primary'))
    .borderRadius(25)
    .onClick(() => {
      this.openInputMethodSettings();
    })
  }

  @Builder
  private SecondaryButton(): void {
    Button({ type: ButtonType.Capsule, stateEffect: false }) {
      Text($r('app.string.input_method_required_recheck'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.key_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(48)
    .backgroundColor(LiquidMaterial.cardBackground())
    .border({ width: LiquidMaterial.borderWidth(), color: LiquidMaterial.borderColor() })
    .borderRadius(24)
    .clip(true)
    .systemMaterial(LiquidMaterial.card())
    .margin({ top: 12 })
    .onClick(() => {
      this.recheckInputMethod();
    })
  }

  build() {
    Column() {
      Blank()
        .height(this.topInset())
        .width('100%')

      Blank()
        .layoutWeight(1)

      Image($r('app.media.icon_liquid'))
        .width(88)
        .height(88)
        .borderRadius(44)
        .clip(true)

      Text($r('app.string.input_method_required_title'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.key_text'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 22 })

      Text($r('app.string.input_method_required_desc'))
        .fontSize(16)
        .fontColor($r('app.color.text_muted'))
        .lineHeight(24)
        .textAlign(TextAlign.Center)
        .margin({ top: 10 })

      Column() {
        this.PrimaryButton()
        this.SecondaryButton()
      }
      .width('100%')
      .margin({ top: 30 })

      Blank()
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 28, right: 28 })
    .backgroundColor($r('app.color.settings_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
