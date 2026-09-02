import { SegmentButton, SegmentButtonOptions, SegmentButtonTextItem } from '@kit.ArkUI';
import { InputHandler, keyboardController } from '../InputMethodExtensionAbility/model/KeyboardController';
import { KeyboardSkinStyle } from '../common/KeyboardSkinStyle';
import { SettingsStore } from '../model/ImeSettings';
import { PinyinCandidate } from '../model/PinyinEngine';
import { SystemSymbolIcon } from './SystemSymbolIcon';

@Component
struct TopCandidateChip {
  candidate: PinyinCandidate = new PinyinCandidate('', '', 0, 0);
  @Prop selected: boolean = false;
  onPress: () => void = () => {};
  @State private pressed: boolean = false;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  build() {
    Button({ type: ButtonType.Capsule, stateEffect: false }) {
      Text(this.candidate.displayWord)
        .fontSize(this.selected ? 18 : 16)
        .fontWeight(this.selected ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
        .maxLines(1)
    }
    .height(32)
    .padding({ left: 12, right: 12 })
    .margin({ right: 6 })
    .backgroundColor(KeyboardSkinStyle.chipBackground(this.skinPreset, this.selected || this.pressed))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(16)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.chipMaterial(this.skinPreset, this.selected || this.pressed))
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

@Component
export struct TopBar {
  @StorageLink('ime.panelSettingsVisible') panelSettingsVisible: boolean = false;
  @StorageLink('ime.panelSettingsTab') @Watch('onPanelSettingsTabChange') panelSettingsTab: number = 0;
  @StorageLink('ime.composing') composing: string = '';
  @StorageLink('ime.candidates') candidates: Array<PinyinCandidate> = [];
  @StorageLink('ime.skinPreset') @Watch('onSkinChange') skinPreset: number = 0;
  @StorageLink('ime.skinKeyColor') @Watch('onSkinChange') skinKeyColor: string = '#F2FFFFFF';
  @StorageLink('subtypeId') subtypeId: string = 'EN';
  @State private panelSelectedIndexes: number[] = [0];
  @State private panelSegmentOptions: SegmentButtonOptions = this.createPanelSegmentOptions();

  aboutToAppear(): void {
    this.syncPanelSelectedIndexes();
  }

  private togglePanelSettings(): void {
    SettingsStore.reloadSettings();
    keyboardController.resizeKeyboardPanel();
    this.panelSettingsVisible = !this.panelSettingsVisible;
  }

  private setPanelSettingsTab(index: number): void {
    this.panelSettingsTab = index;
    this.panelSelectedIndexes = [index];
  }

  private onPanelSettingsTabChange(): void {
    this.syncPanelSelectedIndexes();
  }

  private onSkinChange(): void {
    this.panelSegmentOptions = this.createPanelSegmentOptions();
  }

  private syncPanelSelectedIndexes(): void {
    this.panelSelectedIndexes = [this.panelSettingsTab];
  }

  private idleTitle(): ResourceStr {
    if (this.subtypeId === 'ZH') {
      return $r('app.string.chinese');
    }
    return $r('app.string.english');
  }

  private createPanelSegmentOptions(): SegmentButtonOptions {
    let commonTab: SegmentButtonTextItem = { text: $r('app.string.tab_common') };
    let inputTab: SegmentButtonTextItem = { text: $r('app.string.tab_input') };
    let keyboardTab: SegmentButtonTextItem = { text: $r('app.string.tab_keyboard') };
    return SegmentButtonOptions.capsule({
      buttons: [commonTab, inputTab, keyboardTab],
      multiply: false,
      fontColor: $r('app.color.text_muted'),
      selectedFontColor: $r('app.color.key_text'),
      fontSize: 13,
      selectedFontSize: 13,
      fontWeight: FontWeight.Medium,
      selectedFontWeight: FontWeight.Bold,
      backgroundColor: KeyboardSkinStyle.functionKeyBackground(this.skinPreset, this.skinKeyColor, false, false),
      selectedBackgroundColor: KeyboardSkinStyle.chipBackground(this.skinPreset, true),
      buttonPadding: { left: 6, right: 6, top: 4, bottom: 4 },
      backgroundSystemMaterial: KeyboardSkinStyle.functionKeyMaterial(this.skinPreset, false, false, -1, this.skinKeyColor)
    });
  }

  private selectCandidate(candidate: PinyinCandidate): void {
    for (let i: number = 0; i < this.candidates.length; i++) {
      let item: PinyinCandidate = this.candidates[i];
      if (item.word === candidate.word && item.pinyin === candidate.pinyin) {
        InputHandler.getInstance().selectCandidate(i);
        return;
      }
    }
  }

  build() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Stack() {
          if (KeyboardSkinStyle.usesKeyColorOverlay(this.skinPreset)) {
            Blank()
              .width('100%')
              .height('100%')
              .backgroundColor(KeyboardSkinStyle.primaryBackground(this.skinPreset, false, 37))
              .opacity(KeyboardSkinStyle.keyColorOverlayOpacity(false))
          }
          Text($r('app.string.toolbar_logo_short'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(KeyboardSkinStyle.primaryTextColor(this.skinPreset, 37))
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Center)
      }
      .width(32)
      .height(32)
      .padding(0)
      .backgroundColor(KeyboardSkinStyle.primaryBackground(this.skinPreset, false))
      .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
      .borderRadius(16)
      .clip(true)
      .systemMaterial(KeyboardSkinStyle.primaryMaterial(this.skinPreset, false))
      .margin({ left: 10, right: 8 })
      .onClick(() => {
        this.togglePanelSettings();
      })

      Stack() {
        if (this.panelSettingsVisible) {
          SegmentButton({
            options: this.panelSegmentOptions,
            selectedIndexes: $panelSelectedIndexes,
            maxFontScale: 1,
            enableStateAnimation: true,
            onItemClicked: (index: number) => {
              this.setPanelSettingsTab(index);
            }
          })
          .margin({ left: 2, right: 2 })
        } else if (this.composing.length > 0 || this.candidates.length > 0) {
          Scroll() {
            Row() {
              if (this.composing.length > 0) {
                Text(this.composing)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.primary'))
                  .height(32)
                  .padding({ left: 10, right: 10 })
                  .borderRadius(16)
                  .backgroundColor($r('app.color.composing_background'))
                  .margin({ right: 6 })
              }

              if (this.candidates.length > 0) {
                ForEach(this.candidates, (item: PinyinCandidate) => {
                  TopCandidateChip({
                    candidate: item,
                    selected: this.candidates.length > 0 && this.candidates[0].word === item.word,
                    onPress: () => {
                      this.selectCandidate(item);
                    }
                  })
                }, (item: PinyinCandidate) => item.word + item.pinyin)
              }
            }
            .height(34)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        } else {
          Text(this.idleTitle())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_muted'))
            .height(32)
        }
      }
      .height(34)
      .layoutWeight(1)
      .alignContent(Alignment.Center)
      .renderGroup(true)

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Stack() {
          if (KeyboardSkinStyle.usesKeyColorOverlay(this.skinPreset)) {
            Blank()
              .width('100%')
              .height('100%')
              .backgroundColor(KeyboardSkinStyle.functionKeyBackground(this.skinPreset, this.skinKeyColor, false, false,
                38))
              .opacity(KeyboardSkinStyle.keyColorOverlayOpacity(false))
          }
          SystemSymbolIcon({
            symbol: $r('sys.symbol.chevron_down'),
            color: KeyboardSkinStyle.keyMainTextColor(this.skinPreset, 38),
            iconSize: 18
          })
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Center)
      }
      .width(32)
      .height(32)
      .margin({ left: 8, right: 10 })
      .padding(0)
      .backgroundColor(KeyboardSkinStyle.functionKeyBackground(this.skinPreset, this.skinKeyColor, false, false))
      .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
      .borderRadius(16)
      .clip(true)
      .systemMaterial(KeyboardSkinStyle.functionKeyMaterial(this.skinPreset, false, false, -1, this.skinKeyColor))
      .onClick(() => {
        InputHandler.getInstance().hideKeyboardSelf();
      })
    }
    .width('100%')
    .height(40)
    .alignItems(VerticalAlign.Center)
    .renderGroup(true)
  }
}
