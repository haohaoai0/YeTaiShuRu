import { InputHandler } from '../InputMethodExtensionAbility/model/KeyboardController';
import { KeyboardSkinStyle } from '../common/KeyboardSkinStyle';
import { PinyinCandidate } from '../model/PinyinEngine';

@Component
struct CandidateChip {
  candidate: PinyinCandidate = new PinyinCandidate('', '', 0, 0);
  @Prop selected: boolean = false;
  onPress: () => void = () => {};
  @State private pressed: boolean = false;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  build() {
    Button({ type: ButtonType.Capsule, stateEffect: false }) {
      Text(this.candidate.displayWord)
        .fontSize(this.selected ? 20 : 17)
        .fontWeight(this.selected ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
        .maxLines(1)
    }
    .height(34)
    .padding({ left: 14, right: 14 })
    .margin({ right: 8 })
    .backgroundColor(KeyboardSkinStyle.chipBackground(this.skinPreset, this.selected || this.pressed))
    .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
    .borderRadius(17)
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
export struct CandidateBar {
  @StorageLink('ime.composing') composing: string = '';
  @StorageLink('ime.candidates') candidates: Array<PinyinCandidate> = [];
  @StorageLink('subtypeId') subtypeId: string = 'EN';
  @StorageLink('ime.skinPreset') skinPreset: number = 0;
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';

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
              .backgroundColor(KeyboardSkinStyle.functionKeyBackground(this.skinPreset, this.skinKeyColor, false, false,
                37))
              .opacity(KeyboardSkinStyle.keyColorOverlayOpacity(false))
          }
          Text('☺')
            .fontSize(18)
            .fontColor(KeyboardSkinStyle.keyMainTextColor(this.skinPreset, 37))
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Center)
      }
      .width(34)
      .height(34)
      .padding(0)
      .backgroundColor(KeyboardSkinStyle.functionKeyBackground(this.skinPreset, this.skinKeyColor, false, false))
      .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
      .borderRadius(17)
      .clip(true)
      .systemMaterial(KeyboardSkinStyle.functionKeyMaterial(this.skinPreset, false, false, -1, this.skinKeyColor))
      .margin({ left: 10, right: 8 })

      if (this.composing.length > 0) {
        Text(this.composing)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.primary'))
          .height(34)
          .padding({ left: 10, right: 10 })
          .borderRadius(17)
          .backgroundColor($r('app.color.composing_background'))
          .margin({ right: 8 })
      }

      Scroll() {
        Row() {
          if (this.candidates.length > 0) {
            ForEach(this.candidates, (item: PinyinCandidate) => {
              CandidateChip({
                candidate: item,
                selected: this.candidates.length > 0 && this.candidates[0].word === item.word,
                onPress: () => {
                  this.selectCandidate(item);
                }
              })
            }, (item: PinyinCandidate) => item.word + item.pinyin)
          } else {
            if (this.subtypeId === 'ZH') {
              Text($r('app.string.candidate_hint'))
                .fontSize(14)
                .fontColor(KeyboardSkinStyle.mutedTextColor(this.skinPreset))
                .height(34)
            } else {
              Text($r('app.string.english'))
                .fontSize(14)
                .fontColor(KeyboardSkinStyle.mutedTextColor(this.skinPreset))
                .height(34)
            }
          }
        }
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

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
          Text('⌄')
            .fontSize(20)
            .fontColor(KeyboardSkinStyle.keyMainTextColor(this.skinPreset, 38))
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Center)
      }
      .width(34)
      .height(34)
      .padding(0)
      .backgroundColor(KeyboardSkinStyle.functionKeyBackground(this.skinPreset, this.skinKeyColor, false, false))
      .border({ width: KeyboardSkinStyle.borderWidth(this.skinPreset), color: KeyboardSkinStyle.borderColor(this.skinPreset) })
      .borderRadius(17)
      .clip(true)
      .systemMaterial(KeyboardSkinStyle.functionKeyMaterial(this.skinPreset, false, false, -1, this.skinKeyColor))
      .margin({ left: 8, right: 10 })
      .onClick(() => {
        InputHandler.getInstance().hideKeyboardSelf();
      })
    }
    .width('100%')
    .height(46)
    .alignItems(VerticalAlign.Center)
    .renderGroup(true)
  }
}
