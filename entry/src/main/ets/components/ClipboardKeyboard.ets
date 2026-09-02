import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { inputMethodEngine } from '@kit.IMEKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { KeyboardSkinStyle } from '../common/KeyboardSkinStyle';
import { InputHandler } from '../InputMethodExtensionAbility/model/KeyboardController';
import { ClipboardHistoryItem, SettingsStore } from '../model/ImeSettings';
import { KeyboardMode } from '../model/KeyboardKeyData';
import { FuncKey } from './FuncKey';
import { SystemSymbolIcon } from './SystemSymbolIcon';

const TAG: string = 'ClipboardKeyboard';

@Component
struct ClipboardHistoryCard {
  item: ClipboardHistoryItem = new ClipboardHistoryItem('', 0);
  onPaste: (text: string) => void = (text: string): void => {};
  onDelete: (text: string) => void = (text: string): void => {};
  @State private pressed: boolean = false;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  build() {
    Row() {
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Column() {
          Text(this.item.text)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text($r('app.string.clipboard_tap_to_paste'))
            .fontSize(11)
            .fontColor(KeyboardSkinStyle.mutedTextColor(this.skinPreset))
            .width('100%')
            .margin({ top: 4 })
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(1)
      .height('100%')
      .padding({ left: 12, right: 8, top: 6, bottom: 6 })
      .backgroundColor(Color.Transparent)
      .onTouch((event: TouchEvent): void => {
        if (event.type === TouchType.Down) {
          this.pressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressed = false;
        }
      })
      .onClick((): void => {
        this.onPaste(this.item.text);
      })

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        SystemSymbolIcon({
          symbol: $r('sys.symbol.trash'),
          color: KeyboardSkinStyle.mutedTextColor(this.skinPreset),
          iconSize: 16
        })
      }
      .width(36)
      .height(36)
      .padding(0)
      .margin({ right: 8 })
      .backgroundColor(KeyboardSkinStyle.functionKeyBackground(this.skinPreset, '#F2FFFFFF', false, false))
      .accessibilityText($r('app.string.clipboard_delete'))
      .onClick((): void => {
        this.onDelete(this.item.text);
      })
    }
    .width('100%')
    .height(76)
    .backgroundColor(KeyboardSkinStyle.chipBackground(this.skinPreset, this.pressed))
    .border({
      width: KeyboardSkinStyle.borderWidth(this.skinPreset),
      color: KeyboardSkinStyle.borderColor(this.skinPreset)
    })
    .borderRadius(14)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.cardMaterial(this.skinPreset))
    .renderGroup(true)
  }
}

@Component
export struct ClipboardKeyboard {
  @Consume keyboardMode: number;
  @State private historyItems: Array<ClipboardHistoryItem> = [];
  @State private readFailed: boolean = false;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;
  @StorageLink('ime.securityMode') securityMode: number = inputMethodEngine.SecurityMode.BASIC;

  aboutToAppear(): void {
    this.reloadHistory();
    this.readClipboard();
  }

  private isBasicSecurityMode(): boolean {
    return this.securityMode === inputMethodEngine.SecurityMode.BASIC;
  }

  private reloadHistory(): void {
    this.historyItems = SettingsStore.getClipboardHistory();
  }

  private async readClipboard(): Promise<void> {
    if (this.isBasicSecurityMode()) {
      this.readFailed = false;
      return;
    }
    try {
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      let pasteData: pasteboard.PasteData = await systemPasteboard.getData();
      if (pasteData.hasType(pasteboard.MIMETYPE_TEXT_PLAIN)) {
        let text: string = pasteData.getPrimaryText();
        if (text.trim().length > 0) {
          SettingsStore.addClipboardHistory(text);
        }
      }
      this.readFailed = false;
      this.reloadHistory();
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      this.readFailed = true;
      hilog.error(0x0000, TAG, 'read clipboard failed: %{public}d %{public}s', err.code, err.message);
    }
  }

  private pasteHistoryText(text: string): void {
    InputHandler.getInstance().insertExternalText(text);
  }

  private deleteHistoryText(text: string): void {
    SettingsStore.removeClipboardHistory(text);
    this.reloadHistory();
  }

  private clearHistory(): void {
    SettingsStore.clearClipboardHistory();
    this.reloadHistory();
  }

  build() {
    Column() {
      Row() {
        FuncKey({
          label: 'ABC',
          weight: 1.3,
          onPress: (): void => {
            this.keyboardMode = KeyboardMode.LETTER;
          }
        })
        Text($r('app.string.clipboard_title'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
          .layoutWeight(3.0)
          .textAlign(TextAlign.Center)
        FuncKey({
          label: $r('app.string.clipboard_refresh'),
          weight: 1.3,
          onPress: (): void => {
            this.readClipboard();
          }
        })
      }
      .width('100%')
      .height(48)
      .padding({ left: 4, right: 4 })

      Column() {
        if (this.historyItems.length > 0) {
          List({ space: 7 }) {
            ForEach(this.historyItems, (item: ClipboardHistoryItem, index: number) => {
              ListItem() {
                ClipboardHistoryCard({
                  item: item,
                  onPaste: (text: string): void => {
                    this.pasteHistoryText(text);
                  },
                  onDelete: (text: string): void => {
                    this.deleteHistoryText(text);
                  }
                })
              }
            }, (item: ClipboardHistoryItem, index: number): string => item.createdAt.toString() + '_' + index.toString())
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        } else {
          SystemSymbolIcon({
            symbol: $r('sys.symbol.text_clipboard'),
            color: KeyboardSkinStyle.mutedTextColor(this.skinPreset),
            iconSize: 38
          })
          if (this.isBasicSecurityMode()) {
            Text($r('app.string.clipboard_security_mode_disabled'))
              .fontSize(14)
              .fontColor(KeyboardSkinStyle.mutedTextColor(this.skinPreset))
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          } else if (this.readFailed) {
            Text($r('app.string.clipboard_read_failed'))
              .fontSize(14)
              .fontColor(KeyboardSkinStyle.mutedTextColor(this.skinPreset))
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          } else {
            Text($r('app.string.clipboard_empty'))
              .fontSize(14)
              .fontColor(KeyboardSkinStyle.mutedTextColor(this.skinPreset))
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })

      Row() {
        FuncKey({
          label: $r('app.string.clipboard_clear'),
          weight: 2.0,
          onPress: (): void => {
            if (this.historyItems.length > 0) {
              this.clearHistory();
            }
          }
        })
        FuncKey({
          label: '123',
          weight: 1.5,
          onPress: (): void => {
            this.keyboardMode = KeyboardMode.NUMBER;
          }
        })
        FuncKey({
          label: $r('app.string.panel_symbol_keyboard'),
          weight: 1.5,
          onPress: (): void => {
            this.keyboardMode = KeyboardMode.SYMBOL;
          }
        })
      }
      .width('100%')
      .height(48)
      .padding({ left: 4, right: 4 })
      .margin({ bottom: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 4, bottom: 4 })
  }
}
