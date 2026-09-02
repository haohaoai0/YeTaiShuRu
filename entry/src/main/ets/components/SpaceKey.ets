import { voiceInputManager, VoiceInputState } from '../common/VoiceInputManager';
import { KeyboardSkinStyle } from '../common/KeyboardSkinStyle';
import { InputHandler, keyboardController } from '../InputMethodExtensionAbility/model/KeyboardController';
import { ROUTE_SPEECH_TEXT } from '../model/SettingsLaunch';

@Component
export struct SpaceKey {
  @Prop weight: number = 4.0;
  keyIndex: number = 0;
  @State private pressed: boolean = false;
  @State private longPressTriggered: boolean = false;
  @StorageLink('ime.keyFontScale') keyFontScale: number = 100;
  @StorageLink('ime.longPressDelay') longPressDelay: number = 420;
  @StorageLink('ime.speechInput') speechInputEnabled: boolean = false;
  @StorageLink('ime.voiceInputState') voiceInputState: number = VoiceInputState.IDLE;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';

  private scaledFontSize(baseSize: number): number {
    return Math.round(baseSize * this.keyFontScale / 100);
  }

  private keyLabel(): ResourceStr {
    if (this.voiceInputState === VoiceInputState.STARTING) {
      return $r('app.string.voice_starting_short');
    }
    if (this.voiceInputState === VoiceInputState.LISTENING) {
      return $r('app.string.voice_listening_short');
    }
    if (this.voiceInputState === VoiceInputState.PROCESSING) {
      return $r('app.string.voice_processing_short');
    }
    if (this.voiceInputState === VoiceInputState.ERROR) {
      return $r('app.string.voice_unavailable_short');
    }
    return $r('app.string.space_key_label');
  }

  private voiceLanguage(): string {
    let subtypeId: string | undefined = AppStorage.get<string>('subtypeId');
    if (subtypeId === 'EN') {
      return 'en-US';
    }
    return 'zh-CN';
  }

  private startVoiceInput(): void {
    this.longPressTriggered = true;
    if (!this.speechInputEnabled) {
      keyboardController.openSettings(ROUTE_SPEECH_TEXT);
      return;
    }
    voiceInputManager.start(this.voiceLanguage()).then((started: boolean): void => {
      if (!started) {
        this.pressed = false;
      }
    });
  }

  private stopVoiceInput(): void {
    if (this.speechInputEnabled) {
      voiceInputManager.stop();
    }
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
        Text(this.keyLabel())
          .fontSize(this.scaledFontSize(13))
          .fontWeight(FontWeight.Medium)
          .fontColor(KeyboardSkinStyle.keyHintTextColor(this.skinPreset, this.keyIndex))
          .opacity(this.pressed ? 1 : 0.6)
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
    }
    .layoutWeight(this.weight)
    .height('100%')
    .margin({ left: 3, right: 3 })
    .padding(0)
    .backgroundColor(KeyboardSkinStyle.keyBackground(this.skinPreset, this.skinKeyColor, this.pressed, this.keyIndex))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(14)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.keyMaterial(this.skinPreset, this.pressed, this.keyIndex, this.skinKeyColor))
    .gesture(
      LongPressGesture({ repeat: false, duration: this.longPressDelay })
        .onAction(() => {
          this.startVoiceInput();
        })
        .onActionEnd(() => {
          this.stopVoiceInput();
        })
    )
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.pressed = true;
        this.longPressTriggered = false;
      } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      if (this.longPressTriggered) {
        this.longPressTriggered = false;
        return;
      }
      InputHandler.getInstance().inputSpace();
    })
  }
}
