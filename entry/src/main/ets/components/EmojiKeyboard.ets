import { KeyboardSkinStyle } from '../common/KeyboardSkinStyle';
import { InputHandler } from '../InputMethodExtensionAbility/model/KeyboardController';
import {
  EMOJI_ANIMALS,
  EMOJI_FOOD,
  EMOJI_KAOMOJI,
  EMOJI_PEOPLE,
  EMOJI_SMILEYS,
  EMOJI_SYMBOLS,
  EmojiCategory
} from '../model/EmojiData';
import { SettingsStore } from '../model/ImeSettings';
import { KeyboardMode } from '../model/KeyboardKeyData';
import { FuncKey } from './FuncKey';
import { SystemSymbolIcon } from './SystemSymbolIcon';

@Component
struct EmojiCategoryTab {
  title: ResourceStr = '';
  @Prop selected: boolean = false;
  onPress: () => void = (): void => {};
  @State private pressed: boolean = false;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  build() {
    Button({ type: ButtonType.Capsule, stateEffect: false }) {
      Text(this.title)
        .fontSize(13)
        .fontWeight(this.selected ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
        .maxLines(1)
    }
    .height(32)
    .padding({ left: 13, right: 13 })
    .backgroundColor(KeyboardSkinStyle.chipBackground(this.skinPreset, this.selected || this.pressed))
    .border({
      width: KeyboardSkinStyle.borderWidth(this.skinPreset),
      color: KeyboardSkinStyle.borderColor(this.skinPreset)
    })
    .borderRadius(16)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.chipMaterial(this.skinPreset, this.selected || this.pressed))
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick((): void => {
      this.onPress();
    })
  }
}

@Component
struct EmojiKey {
  value: string = '';
  @Prop wide: boolean = false;
  onPress: (value: string) => void = (value: string): void => {};
  @State private pressed: boolean = false;
  @StorageLink('ime.skinPreset') skinPreset: number = 0;
  @StorageLink('ime.skinKeyColor') skinKeyColor: string = '#F2FFFFFF';

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Text(this.value)
        .fontSize(this.wide ? 13 : 26)
        .fontWeight(this.wide ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(KeyboardSkinStyle.keyTextColor(this.skinPreset))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(44)
    .padding({ left: this.wide ? 6 : 0, right: this.wide ? 6 : 0 })
    .backgroundColor(KeyboardSkinStyle.keyBackground(this.skinPreset, this.skinKeyColor, this.pressed))
    .border({
      width: KeyboardSkinStyle.borderWidth(this.skinPreset),
      color: KeyboardSkinStyle.borderColor(this.skinPreset)
    })
    .borderRadius(12)
    .clip(true)
    .systemMaterial(KeyboardSkinStyle.keyMaterial(this.skinPreset, this.pressed))
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick((): void => {
      this.onPress(this.value);
    })
  }
}

@Component
export struct EmojiKeyboard {
  @Consume keyboardMode: number;
  @State private selectedCategory: number = EmojiCategory.SMILEYS;
  @State private recentItems: Array<string> = [];
  @StorageLink('ime.skinPreset') skinPreset: number = 0;

  aboutToAppear(): void {
    this.reloadRecentItems();
  }

  private reloadRecentItems(): void {
    this.recentItems = SettingsStore.getRecentEmoji();
  }

  private setCategory(category: number): void {
    this.selectedCategory = category;
    if (category === EmojiCategory.RECENT) {
      this.reloadRecentItems();
    }
  }

  private categoryItems(): Array<string> {
    if (this.selectedCategory === EmojiCategory.RECENT) {
      return this.recentItems;
    }
    if (this.selectedCategory === EmojiCategory.PEOPLE) {
      return EMOJI_PEOPLE;
    }
    if (this.selectedCategory === EmojiCategory.ANIMALS) {
      return EMOJI_ANIMALS;
    }
    if (this.selectedCategory === EmojiCategory.FOOD) {
      return EMOJI_FOOD;
    }
    if (this.selectedCategory === EmojiCategory.SYMBOLS) {
      return EMOJI_SYMBOLS;
    }
    if (this.selectedCategory === EmojiCategory.KAOMOJI) {
      return EMOJI_KAOMOJI;
    }
    return EMOJI_SMILEYS;
  }

  private gridColumns(): string {
    if (this.selectedCategory === EmojiCategory.KAOMOJI) {
      return '1fr 1fr 1fr';
    }
    return '1fr 1fr 1fr 1fr 1fr 1fr 1fr';
  }

  private insertEmoji(value: string): void {
    InputHandler.getInstance().insertExternalText(value);
    SettingsStore.bumpRecentEmoji(value);
    this.reloadRecentItems();
  }

  build() {
    Column() {
      Scroll() {
        Row({ space: 6 }) {
          EmojiCategoryTab({
            title: $r('app.string.emoji_category_recent'),
            selected: this.selectedCategory === EmojiCategory.RECENT,
            onPress: (): void => {
              this.setCategory(EmojiCategory.RECENT);
            }
          })
          EmojiCategoryTab({
            title: $r('app.string.emoji_category_smileys'),
            selected: this.selectedCategory === EmojiCategory.SMILEYS,
            onPress: (): void => {
              this.setCategory(EmojiCategory.SMILEYS);
            }
          })
          EmojiCategoryTab({
            title: $r('app.string.emoji_category_people'),
            selected: this.selectedCategory === EmojiCategory.PEOPLE,
            onPress: (): void => {
              this.setCategory(EmojiCategory.PEOPLE);
            }
          })
          EmojiCategoryTab({
            title: $r('app.string.emoji_category_animals'),
            selected: this.selectedCategory === EmojiCategory.ANIMALS,
            onPress: (): void => {
              this.setCategory(EmojiCategory.ANIMALS);
            }
          })
          EmojiCategoryTab({
            title: $r('app.string.emoji_category_food'),
            selected: this.selectedCategory === EmojiCategory.FOOD,
            onPress: (): void => {
              this.setCategory(EmojiCategory.FOOD);
            }
          })
          EmojiCategoryTab({
            title: $r('app.string.emoji_category_symbols'),
            selected: this.selectedCategory === EmojiCategory.SYMBOLS,
            onPress: (): void => {
              this.setCategory(EmojiCategory.SYMBOLS);
            }
          })
          EmojiCategoryTab({
            title: $r('app.string.emoji_category_kaomoji'),
            selected: this.selectedCategory === EmojiCategory.KAOMOJI,
            onPress: (): void => {
              this.setCategory(EmojiCategory.KAOMOJI);
            }
          })
        }
        .height(36)
        .padding({ left: 7, right: 7 })
      }
      .width('100%')
      .height(40)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      Stack() {
        if (this.categoryItems().length > 0) {
          Grid() {
            ForEach(this.categoryItems(), (value: string, index: number) => {
              GridItem() {
                EmojiKey({
                  value: value,
                  wide: this.selectedCategory === EmojiCategory.KAOMOJI,
                  onPress: (selectedValue: string): void => {
                    this.insertEmoji(selectedValue);
                  }
                })
              }
            }, (value: string, index: number): string => value + '_' + index.toString())
          }
          .columnsTemplate(this.gridColumns())
          .columnsGap(4)
          .rowsGap(4)
          .width('100%')
          .height('100%')
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        } else {
          Column() {
            SystemSymbolIcon({
              symbol: $r('sys.symbol.face_smiling'),
              color: KeyboardSkinStyle.mutedTextColor(this.skinPreset),
              iconSize: 38
            })
            Text($r('app.string.emoji_recent_empty'))
              .fontSize(14)
              .fontColor(KeyboardSkinStyle.mutedTextColor(this.skinPreset))
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .renderGroup(true)

      Row() {
        FuncKey({
          label: 'ABC',
          weight: 1.5,
          onPress: (): void => {
            this.keyboardMode = KeyboardMode.LETTER;
          }
        })
        FuncKey({
          label: $r('app.string.panel_symbol_keyboard'),
          weight: 1.5,
          onPress: (): void => {
            this.keyboardMode = KeyboardMode.SYMBOL;
          }
        })
        FuncKey({
          label: $r('app.string.space_key_label'),
          weight: 3.5,
          onPress: (): void => {
            InputHandler.getInstance().inputSpace();
          }
        })
        FuncKey({
          label: '⌫',
          weight: 1.5,
          onPress: (): void => {
            InputHandler.getInstance().deleteSmart();
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
