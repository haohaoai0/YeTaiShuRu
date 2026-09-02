import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'ImeSettings';
const PREF_STORE: string = 'liquid_ime_settings';
const SKIN_IMAGE_FILE_NAME: string = 'keyboard_skin_background.jpg';
const KEY_LAYOUT_MODE: string = 'ime.layoutMode';
const KEY_KEYBOARD_HEIGHT_PERCENT: string = 'ime.keyboardHeightPercent';
const KEY_KEYBOARD_DOCK_MODE: string = 'ime.keyboardDockMode';
const KEY_NUMBER_ROW: string = 'ime.numberRow';
const KEY_ENTER_SEND: string = 'ime.enterSend';
const KEY_SWAP_LANG_NUMBER: string = 'ime.swapLangNumber';
const KEY_SWIPE_INPUT: string = 'ime.swipeInput';
const KEY_UPPER_CASE: string = 'ime.upperCase';
const KEY_HAPTIC_STRENGTH: string = 'ime.hapticStrength';
const KEY_SOUND_VOLUME: string = 'ime.soundVolume';
const KEY_SOUND_EFFECT: string = 'ime.soundEffect';
const KEY_KEY_POPUP: string = 'ime.keyPopup';
const KEY_KEY_FONT_SCALE: string = 'ime.keyFontScale';
const KEY_LONG_PRESS_DELAY: string = 'ime.longPressDelay';
const KEY_SPEECH_INPUT: string = 'ime.speechInput';
const KEY_FUZZY_PINYIN: string = 'ime.fuzzyPinyin';
const KEY_MIXED_INPUT: string = 'ime.mixedInput';
const KEY_SINGLE_CHAR_PRIORITY: string = 'ime.singleCharPriority';
const KEY_TRADITIONAL: string = 'ime.traditionalInput';
const KEY_SYSTEM_MATERIAL_ENABLED: string = 'ime.systemMaterialEnabled';
const KEY_SYSTEM_MATERIAL_LEVEL: string = 'ime.systemMaterialLevel';
const KEY_SKIN_PRESET: string = 'ime.skinPreset';
const KEY_SKIN_BACKGROUND_MODE: string = 'ime.skinBackgroundMode';
const KEY_SKIN_BACKGROUND_COLOR: string = 'ime.skinBackgroundColor';
const KEY_SKIN_KEY_COLOR: string = 'ime.skinKeyColor';
const KEY_SKIN_IMAGE_URI: string = 'ime.skinImageUri';
const KEY_SKIN_IMAGE_PATH: string = 'ime.skinImagePath';
const KEY_SKIN_IMAGE_DATA_BASE64: string = 'ime.skinImageDataBase64';
const KEY_SKIN_IMAGE_DATA_CHUNK_COUNT: string = 'ime.skinImageDataChunkCount';
const KEY_SKIN_IMAGE_DATA_CHUNK_PREFIX: string = 'ime.skinImageDataChunk.';
const KEY_SKIN_IMAGE_REVISION: string = 'ime.skinImageRevision';
const KEY_SKIN_IMAGE_AREA: string = 'ime.skinImageArea';
const KEY_SKIN_IMAGE_BLUR: string = 'ime.skinImageBlur';
const KEY_RECENT_WORDS: string = 'ime.recentWords';
const KEY_CLIPBOARD_HISTORY: string = 'ime.clipboardHistory';
const KEY_RECENT_EMOJI: string = 'ime.recentEmoji';
const EVENT_KEYBOARD_HEIGHT_CHANGED: string = 'com.example.liquidime.event.KEYBOARD_HEIGHT_CHANGED';
const EVENT_SETTINGS_CHANGED: string = 'com.example.liquidime.event.SETTINGS_CHANGED';
const KEYBOARD_HEIGHT_DEFAULT_PERCENT: number = 32;
const KEYBOARD_HEIGHT_MIN_PERCENT: number = 24;
const KEYBOARD_HEIGHT_MAX_PERCENT: number = 42;
const KEY_FONT_SCALE_DEFAULT: number = 100;
const KEY_FONT_SCALE_MIN: number = 90;
const KEY_FONT_SCALE_MAX: number = 120;
const SKIN_IMAGE_BLUR_MIN: number = 0;
const SKIN_IMAGE_BLUR_MAX: number = 20;
const SKIN_IMAGE_DATA_CHUNK_SIZE: number = 6000;
const CLIPBOARD_HISTORY_MAX_ITEMS: number = 20;
const CLIPBOARD_HISTORY_MAX_ITEM_LENGTH: number = 200000;
const CLIPBOARD_HISTORY_MAX_TOTAL_LENGTH: number = 500000;
const RECENT_EMOJI_MAX_ITEMS: number = 30;

export enum KeyboardLayoutMode {
  QWERTY26 = 26,
  T9 = 9,
  XIAOHE_SHUANGPIN = 27
}

export enum KeyboardDockMode {
  FULL = 0,
  LEFT = 1,
  RIGHT = 2
}

export enum SystemMaterialLevelMode {
  ULTRA_THIN = 0,
  THIN = 1,
  REGULAR = 2,
  THICK = 3,
  ULTRA_THICK = 4,
  ADAPTIVE = 10
}

export enum KeyboardSkinPresetMode {
  LIQUID = 0,
  MINT = 1,
  NIGHT = 2,
  SUNSET = 3,
  RAINBOW = 4,
  RAINBOW_TEXT = 5,
  CUSTOM = 99
}

export enum KeyboardSkinBackgroundMode {
  COLOR = 0,
  IMAGE = 1
}

export enum KeyboardSkinImageAreaMode {
  CENTER = 0,
  TOP = 1,
  BOTTOM = 2,
  LEFT = 3,
  RIGHT = 4
}

export class ImeSettings {
  layoutMode: number = KeyboardLayoutMode.QWERTY26;
  keyboardHeightPercent: number = KEYBOARD_HEIGHT_DEFAULT_PERCENT;
  keyboardDockMode: number = KeyboardDockMode.FULL;
  numberRowEnabled: boolean = true;
  enterSendEnabled: boolean = false;
  swapLangNumberEnabled: boolean = false;
  swipeInputEnabled: boolean = false;
  upperCaseEnabled: boolean = false;
  hapticStrength: number = 45;
  soundVolume: number = 0;
  soundEffectEnabled: boolean = false;
  keyPopupEnabled: boolean = true;
  keyFontScale: number = KEY_FONT_SCALE_DEFAULT;
  longPressDelay: number = 420;
  speechInputEnabled: boolean = false;
  fuzzyPinyinEnabled: boolean = false;
  mixedInputEnabled: boolean = true;
  singleCharPriorityEnabled: boolean = true;
  traditionalInputEnabled: boolean = false;
  systemMaterialEnabled: boolean = true;
  systemMaterialLevel: number = SystemMaterialLevelMode.REGULAR;
  skinPreset: number = KeyboardSkinPresetMode.LIQUID;
  skinBackgroundMode: number = KeyboardSkinBackgroundMode.COLOR;
  skinBackgroundColor: string = '#FFF1F4F9';
  skinKeyColor: string = '#F2FFFFFF';
  skinImageUri: string = '';
  skinImagePath: string = '';
  skinImageDataBase64: string = '';
  skinImageRevision: string = '';
  skinImageArea: number = KeyboardSkinImageAreaMode.CENTER;
  skinImageBlur: number = 0;
}

export class RecentWord {
  word: string = '';
  score: number = 0;

  constructor(word: string, score: number) {
    this.word = word;
    this.score = score;
  }
}

export class ClipboardHistoryItem {
  text: string = '';
  createdAt: number = 0;

  constructor(text: string, createdAt: number) {
    this.text = text;
    this.createdAt = createdAt;
  }
}

export class SettingsStore {
  private static context: common.Context | undefined = undefined;
  private static prefs: preferences.Preferences | undefined = undefined;
  private static settings: ImeSettings = new ImeSettings();
  private static recentWords: Array<RecentWord> = [];
  private static clipboardHistory: Array<ClipboardHistoryItem> = [];
  private static recentEmoji: Array<string> = [];

  public static init(context: common.Context): void {
    SettingsStore.context = context.getApplicationContext();
    try {
      SettingsStore.openPreferences();
      SettingsStore.loadSettings();
      SettingsStore.loadRecentWords();
      SettingsStore.loadClipboardHistory();
      SettingsStore.loadRecentEmoji();
    } catch (e) {
      hilog.error(0x0000, TAG, 'init settings failed');
      SettingsStore.settings = new ImeSettings();
      SettingsStore.recentWords = [];
      SettingsStore.clipboardHistory = [];
      SettingsStore.recentEmoji = [];
    }
    SettingsStore.publishSettings();
  }

  public static getSettings(): ImeSettings {
    return SettingsStore.settings;
  }

  public static reloadSettings(): void {
    if (SettingsStore.context !== undefined) {
      SettingsStore.openPreferences();
    }
    if (SettingsStore.prefs === undefined) {
      return;
    }
    SettingsStore.loadSettings();
    SettingsStore.publishSettings();
  }

  public static getLayoutMode(): number {
    return SettingsStore.settings.layoutMode;
  }

  public static getKeyboardHeightPercent(): number {
    return SettingsStore.clampKeyboardHeightPercent(SettingsStore.settings.keyboardHeightPercent);
  }

  public static applyKeyboardHeightPercent(value: number): void {
    SettingsStore.settings.keyboardHeightPercent = SettingsStore.clampKeyboardHeightPercent(value);
    AppStorage.setOrCreate(KEY_KEYBOARD_HEIGHT_PERCENT, SettingsStore.settings.keyboardHeightPercent);
  }

  public static updateLayoutMode(value: number): void {
    SettingsStore.settings.layoutMode = value;
    SettingsStore.saveNumber(KEY_LAYOUT_MODE, value);
    SettingsStore.publishSettings();
    SettingsStore.publishSettingsChanged();
  }

  public static updateBoolean(key: string, enabled: boolean): void {
    if (key === KEY_NUMBER_ROW) {
      SettingsStore.settings.numberRowEnabled = enabled;
    } else if (key === KEY_ENTER_SEND) {
      SettingsStore.settings.enterSendEnabled = enabled;
    } else if (key === KEY_SWAP_LANG_NUMBER) {
      SettingsStore.settings.swapLangNumberEnabled = enabled;
    } else if (key === KEY_SWIPE_INPUT) {
      SettingsStore.settings.swipeInputEnabled = enabled;
    } else if (key === KEY_UPPER_CASE) {
      SettingsStore.settings.upperCaseEnabled = enabled;
    } else if (key === KEY_SOUND_EFFECT) {
      SettingsStore.settings.soundEffectEnabled = enabled;
    } else if (key === KEY_KEY_POPUP) {
      SettingsStore.settings.keyPopupEnabled = enabled;
    } else if (key === KEY_SPEECH_INPUT) {
      SettingsStore.settings.speechInputEnabled = enabled;
    } else if (key === KEY_FUZZY_PINYIN) {
      SettingsStore.settings.fuzzyPinyinEnabled = enabled;
    } else if (key === KEY_MIXED_INPUT) {
      SettingsStore.settings.mixedInputEnabled = enabled;
    } else if (key === KEY_SINGLE_CHAR_PRIORITY) {
      SettingsStore.settings.singleCharPriorityEnabled = enabled;
    } else if (key === KEY_TRADITIONAL) {
      SettingsStore.settings.traditionalInputEnabled = enabled;
    } else if (key === KEY_SYSTEM_MATERIAL_ENABLED) {
      SettingsStore.settings.systemMaterialEnabled = enabled;
    }
    SettingsStore.saveBoolean(key, enabled);
    SettingsStore.publishSettings();
    SettingsStore.publishSettingsChanged();
  }

  public static updateNumber(key: string, value: number): void {
    let keyboardHeightChanged: boolean = false;
    if (key === KEY_KEYBOARD_HEIGHT_PERCENT) {
      SettingsStore.settings.keyboardHeightPercent = SettingsStore.clampKeyboardHeightPercent(value);
      value = SettingsStore.settings.keyboardHeightPercent;
      keyboardHeightChanged = true;
    } else if (key === KEY_KEYBOARD_DOCK_MODE) {
      SettingsStore.settings.keyboardDockMode = SettingsStore.clampKeyboardDockMode(value);
      value = SettingsStore.settings.keyboardDockMode;
    } else if (key === KEY_HAPTIC_STRENGTH) {
      SettingsStore.settings.hapticStrength = value;
    } else if (key === KEY_SOUND_VOLUME) {
      SettingsStore.settings.soundVolume = value;
    } else if (key === KEY_KEY_FONT_SCALE) {
      SettingsStore.settings.keyFontScale = SettingsStore.clampKeyFontScale(value);
      value = SettingsStore.settings.keyFontScale;
    } else if (key === KEY_LONG_PRESS_DELAY) {
      SettingsStore.settings.longPressDelay = value;
    } else if (key === KEY_SYSTEM_MATERIAL_LEVEL) {
      SettingsStore.settings.systemMaterialLevel = SettingsStore.clampSystemMaterialLevel(value);
      value = SettingsStore.settings.systemMaterialLevel;
    } else if (key === KEY_SKIN_PRESET) {
      SettingsStore.settings.skinPreset = value;
    } else if (key === KEY_SKIN_BACKGROUND_MODE) {
      SettingsStore.settings.skinBackgroundMode = value;
    } else if (key === KEY_SKIN_IMAGE_AREA) {
      SettingsStore.settings.skinImageArea = value;
    } else if (key === KEY_SKIN_IMAGE_BLUR) {
      SettingsStore.settings.skinImageBlur = SettingsStore.clampSkinImageBlur(value);
      value = SettingsStore.settings.skinImageBlur;
    }
    SettingsStore.saveNumber(key, value);
    SettingsStore.publishSettings();
    SettingsStore.publishSettingsChanged();
    if (keyboardHeightChanged) {
      SettingsStore.publishKeyboardHeightChanged(value);
    }
  }

  public static updateString(key: string, value: string): void {
    if (key === KEY_SKIN_BACKGROUND_COLOR) {
      SettingsStore.settings.skinBackgroundColor = value;
    } else if (key === KEY_SKIN_KEY_COLOR) {
      SettingsStore.settings.skinKeyColor = value;
    } else if (key === KEY_SKIN_IMAGE_URI) {
      SettingsStore.settings.skinImageUri = value;
    } else if (key === KEY_SKIN_IMAGE_PATH) {
      SettingsStore.settings.skinImagePath = value;
    } else if (key === KEY_SKIN_IMAGE_REVISION) {
      SettingsStore.settings.skinImageRevision = value;
    }
    SettingsStore.saveString(key, value);
    SettingsStore.publishSettings();
    SettingsStore.publishSettingsChanged();
  }

  public static applySkinImage(uri: string, path: string, data: Uint8Array): void {
    let sharedPath: string = SettingsStore.writeSharedSkinImageFile(data);
    let imageDataBase64: string = SettingsStore.encodeImageData(data);
    let storedPath: string = path;
    let storedUri: string = uri;
    if (sharedPath.length > 0) {
      storedPath = sharedPath;
      storedUri = fileUri.getUriFromPath(sharedPath);
    }
    let revision: string = SettingsStore.nextRevision(data.length);
    SettingsStore.settings.skinPreset = KeyboardSkinPresetMode.CUSTOM;
    SettingsStore.settings.skinBackgroundMode = KeyboardSkinBackgroundMode.IMAGE;
    SettingsStore.settings.skinKeyColor = '#88FFFFFF';
    SettingsStore.settings.skinImageUri = storedUri;
    SettingsStore.settings.skinImagePath = storedPath;
    SettingsStore.settings.skinImageDataBase64 = imageDataBase64;
    SettingsStore.settings.skinImageRevision = revision;
    SettingsStore.settings.skinImageBlur = 0;
    SettingsStore.saveSkinImageState(storedUri, storedPath, imageDataBase64, revision);
    SettingsStore.publishSettings();
    SettingsStore.publishSettingsChanged();
  }

  public static clearSkinImage(): void {
    let revision: string = SettingsStore.nextRevision(0);
    SettingsStore.settings.skinImageUri = '';
    SettingsStore.settings.skinImagePath = '';
    SettingsStore.settings.skinImageDataBase64 = '';
    SettingsStore.settings.skinImageRevision = revision;
    SettingsStore.settings.skinBackgroundMode = KeyboardSkinBackgroundMode.COLOR;
    SettingsStore.saveClearedSkinImageState(revision);
    SettingsStore.saveImageDataBase64('');
    SettingsStore.publishSettings();
    SettingsStore.publishSettingsChanged();
  }

  public static loadSkinImageData(): Uint8Array {
    if (SettingsStore.context !== undefined) {
      SettingsStore.openPreferences();
    }
    if (SettingsStore.prefs === undefined) {
      return new Uint8Array(0);
    }
    let base64Value: string = SettingsStore.settings.skinImageDataBase64;
    if (base64Value.length === 0) {
      base64Value = SettingsStore.readImageDataBase64();
    }
    if (base64Value.length > 0) {
      return SettingsStore.decodeImageData(base64Value);
    }
    try {
      let stored: preferences.ValueType = SettingsStore.prefs.getSync('ime.skinImageData', new Uint8Array(0));
      if (stored instanceof Uint8Array) {
        return stored;
      }
    } catch (e) {
      hilog.error(0x0000, TAG, 'read skin image data failed');
    }
    return new Uint8Array(0);
  }

  public static getRecentBoost(word: string): number {
    for (let i: number = 0; i < SettingsStore.recentWords.length; i++) {
      let item: RecentWord = SettingsStore.recentWords[i];
      if (item.word === word) {
        return item.score * 10000;
      }
    }
    return 0;
  }

  public static getRecentWordCount(): number {
    return SettingsStore.recentWords.length;
  }

  public static clearRecentWords(): void {
    SettingsStore.recentWords = [];
    SettingsStore.saveRecentWords();
  }

  public static bumpRecentWord(word: string): void {
    if (word.length === 0) {
      return;
    }
    let found: boolean = false;
    for (let i: number = 0; i < SettingsStore.recentWords.length; i++) {
      let item: RecentWord = SettingsStore.recentWords[i];
      if (item.word === word) {
        item.score = item.score + 1;
        found = true;
      }
    }
    if (!found) {
      SettingsStore.recentWords.push(new RecentWord(word, 1));
    }
    SettingsStore.recentWords.sort((left: RecentWord, right: RecentWord): number => {
      return right.score - left.score;
    });
    if (SettingsStore.recentWords.length > 80) {
      SettingsStore.recentWords.splice(80, SettingsStore.recentWords.length - 80);
    }
    SettingsStore.saveRecentWords();
  }

  public static getClipboardHistory(): Array<ClipboardHistoryItem> {
    let result: Array<ClipboardHistoryItem> = [];
    for (let i: number = 0; i < SettingsStore.clipboardHistory.length; i++) {
      let item: ClipboardHistoryItem = SettingsStore.clipboardHistory[i];
      result.push(new ClipboardHistoryItem(item.text, item.createdAt));
    }
    return result;
  }

  public static addClipboardHistory(text: string): void {
    if (text.trim().length === 0 || text.length > CLIPBOARD_HISTORY_MAX_ITEM_LENGTH) {
      return;
    }
    let updated: Array<ClipboardHistoryItem> = [];
    updated.push(new ClipboardHistoryItem(text, Date.now()));
    for (let i: number = 0; i < SettingsStore.clipboardHistory.length; i++) {
      let item: ClipboardHistoryItem = SettingsStore.clipboardHistory[i];
      if (item.text !== text) {
        updated.push(item);
      }
    }
    SettingsStore.clipboardHistory = updated;
    SettingsStore.pruneClipboardHistory();
    SettingsStore.saveClipboardHistory();
  }

  public static removeClipboardHistory(text: string): void {
    let updated: Array<ClipboardHistoryItem> = [];
    for (let i: number = 0; i < SettingsStore.clipboardHistory.length; i++) {
      let item: ClipboardHistoryItem = SettingsStore.clipboardHistory[i];
      if (item.text !== text) {
        updated.push(item);
      }
    }
    SettingsStore.clipboardHistory = updated;
    SettingsStore.saveClipboardHistory();
  }

  public static clearClipboardHistory(): void {
    SettingsStore.clipboardHistory = [];
    SettingsStore.saveClipboardHistory();
  }

  public static getRecentEmoji(): Array<string> {
    let result: Array<string> = [];
    for (let i: number = 0; i < SettingsStore.recentEmoji.length; i++) {
      result.push(SettingsStore.recentEmoji[i]);
    }
    return result;
  }

  public static bumpRecentEmoji(value: string): void {
    if (value.trim().length === 0) {
      return;
    }
    let updated: Array<string> = [];
    updated.push(value);
    for (let i: number = 0; i < SettingsStore.recentEmoji.length; i++) {
      let item: string = SettingsStore.recentEmoji[i];
      if (item !== value && updated.length < RECENT_EMOJI_MAX_ITEMS) {
        updated.push(item);
      }
    }
    SettingsStore.recentEmoji = updated;
    SettingsStore.saveRecentEmoji();
  }

  public static settingsKeyNumberRow(): string {
    return KEY_NUMBER_ROW;
  }

  public static settingsKeyKeyboardHeightPercent(): string {
    return KEY_KEYBOARD_HEIGHT_PERCENT;
  }

  public static settingsKeyKeyboardDockMode(): string {
    return KEY_KEYBOARD_DOCK_MODE;
  }

  public static keyboardHeightChangedEvent(): string {
    return EVENT_KEYBOARD_HEIGHT_CHANGED;
  }

  public static settingsChangedEvent(): string {
    return EVENT_SETTINGS_CHANGED;
  }

  public static settingsKeyEnterSend(): string {
    return KEY_ENTER_SEND;
  }

  public static settingsKeySwapLangNumber(): string {
    return KEY_SWAP_LANG_NUMBER;
  }

  public static settingsKeySwipeInput(): string {
    return KEY_SWIPE_INPUT;
  }

  public static settingsKeyUpperCase(): string {
    return KEY_UPPER_CASE;
  }

  public static settingsKeyHapticStrength(): string {
    return KEY_HAPTIC_STRENGTH;
  }

  public static settingsKeySoundVolume(): string {
    return KEY_SOUND_VOLUME;
  }

  public static settingsKeySoundEffect(): string {
    return KEY_SOUND_EFFECT;
  }

  public static settingsKeyKeyPopup(): string {
    return KEY_KEY_POPUP;
  }

  public static settingsKeyKeyFontScale(): string {
    return KEY_KEY_FONT_SCALE;
  }

  public static settingsKeyLongPressDelay(): string {
    return KEY_LONG_PRESS_DELAY;
  }

  public static settingsKeySpeechInput(): string {
    return KEY_SPEECH_INPUT;
  }

  public static settingsKeyFuzzyPinyin(): string {
    return KEY_FUZZY_PINYIN;
  }

  public static settingsKeyMixedInput(): string {
    return KEY_MIXED_INPUT;
  }

  public static settingsKeySingleCharPriority(): string {
    return KEY_SINGLE_CHAR_PRIORITY;
  }

  public static settingsKeyTraditional(): string {
    return KEY_TRADITIONAL;
  }

  public static settingsKeySystemMaterialEnabled(): string {
    return KEY_SYSTEM_MATERIAL_ENABLED;
  }

  public static settingsKeySystemMaterialLevel(): string {
    return KEY_SYSTEM_MATERIAL_LEVEL;
  }

  public static settingsKeySkinPreset(): string {
    return KEY_SKIN_PRESET;
  }

  public static settingsKeySkinBackgroundMode(): string {
    return KEY_SKIN_BACKGROUND_MODE;
  }

  public static settingsKeySkinBackgroundColor(): string {
    return KEY_SKIN_BACKGROUND_COLOR;
  }

  public static settingsKeySkinKeyColor(): string {
    return KEY_SKIN_KEY_COLOR;
  }

  public static settingsKeySkinImageUri(): string {
    return KEY_SKIN_IMAGE_URI;
  }

  public static settingsKeySkinImagePath(): string {
    return KEY_SKIN_IMAGE_PATH;
  }

  public static settingsKeySkinImageRevision(): string {
    return KEY_SKIN_IMAGE_REVISION;
  }

  public static settingsKeySkinImageArea(): string {
    return KEY_SKIN_IMAGE_AREA;
  }

  public static settingsKeySkinImageBlur(): string {
    return KEY_SKIN_IMAGE_BLUR;
  }

  private static preferencesOptions(): preferences.Options {
    let options: preferences.Options = { name: PREF_STORE };
    return options;
  }

  private static snapshotLine(key: string, value: string): string {
    return key + '=' + encodeURIComponent(value);
  }

  private static snapshotBoolean(value: boolean): string {
    return value ? '1' : '0';
  }

  private static snapshotNumber(value: number): string {
    return value.toString();
  }

  private static decodeSnapshotValue(value: string): string {
    try {
      return decodeURIComponent(value);
    } catch (e) {
      return value;
    }
  }

  private static snapshotToBoolean(value: string, defaultValue: boolean): boolean {
    if (value === '1' || value === 'true') {
      return true;
    }
    if (value === '0' || value === 'false') {
      return false;
    }
    return defaultValue;
  }

  private static snapshotToNumber(value: string, defaultValue: number): number {
    let parsed: number = parseInt(value);
    if (Number.isNaN(parsed)) {
      return defaultValue;
    }
    return parsed;
  }

  private static buildSettingsSnapshot(): string {
    let value: ImeSettings = SettingsStore.settings;
    let lines: Array<string> = [];
    lines.push(SettingsStore.snapshotLine('version', '1'));
    lines.push(SettingsStore.snapshotLine(KEY_LAYOUT_MODE, SettingsStore.snapshotNumber(value.layoutMode)));
    lines.push(SettingsStore.snapshotLine(KEY_KEYBOARD_HEIGHT_PERCENT,
      SettingsStore.snapshotNumber(value.keyboardHeightPercent)));
    lines.push(SettingsStore.snapshotLine(KEY_KEYBOARD_DOCK_MODE,
      SettingsStore.snapshotNumber(value.keyboardDockMode)));
    lines.push(SettingsStore.snapshotLine(KEY_NUMBER_ROW, SettingsStore.snapshotBoolean(value.numberRowEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_ENTER_SEND, SettingsStore.snapshotBoolean(value.enterSendEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_SWAP_LANG_NUMBER, SettingsStore.snapshotBoolean(value.swapLangNumberEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_SWIPE_INPUT, SettingsStore.snapshotBoolean(value.swipeInputEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_UPPER_CASE, SettingsStore.snapshotBoolean(value.upperCaseEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_HAPTIC_STRENGTH, SettingsStore.snapshotNumber(value.hapticStrength)));
    lines.push(SettingsStore.snapshotLine(KEY_SOUND_VOLUME, SettingsStore.snapshotNumber(value.soundVolume)));
    lines.push(SettingsStore.snapshotLine(KEY_SOUND_EFFECT, SettingsStore.snapshotBoolean(value.soundEffectEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_KEY_POPUP, SettingsStore.snapshotBoolean(value.keyPopupEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_KEY_FONT_SCALE, SettingsStore.snapshotNumber(value.keyFontScale)));
    lines.push(SettingsStore.snapshotLine(KEY_LONG_PRESS_DELAY, SettingsStore.snapshotNumber(value.longPressDelay)));
    lines.push(SettingsStore.snapshotLine(KEY_SPEECH_INPUT,
      SettingsStore.snapshotBoolean(value.speechInputEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_FUZZY_PINYIN, SettingsStore.snapshotBoolean(value.fuzzyPinyinEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_MIXED_INPUT, SettingsStore.snapshotBoolean(value.mixedInputEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_SINGLE_CHAR_PRIORITY,
      SettingsStore.snapshotBoolean(value.singleCharPriorityEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_TRADITIONAL, SettingsStore.snapshotBoolean(value.traditionalInputEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_SYSTEM_MATERIAL_ENABLED,
      SettingsStore.snapshotBoolean(value.systemMaterialEnabled)));
    lines.push(SettingsStore.snapshotLine(KEY_SYSTEM_MATERIAL_LEVEL,
      SettingsStore.snapshotNumber(value.systemMaterialLevel)));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_PRESET, SettingsStore.snapshotNumber(value.skinPreset)));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_BACKGROUND_MODE,
      SettingsStore.snapshotNumber(value.skinBackgroundMode)));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_BACKGROUND_COLOR, value.skinBackgroundColor));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_KEY_COLOR, value.skinKeyColor));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_IMAGE_URI, value.skinImageUri));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_IMAGE_PATH, value.skinImagePath));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_IMAGE_DATA_BASE64, value.skinImageDataBase64));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_IMAGE_REVISION, value.skinImageRevision));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_IMAGE_AREA, SettingsStore.snapshotNumber(value.skinImageArea)));
    lines.push(SettingsStore.snapshotLine(KEY_SKIN_IMAGE_BLUR, SettingsStore.snapshotNumber(value.skinImageBlur)));
    return lines.join('\n');
  }

  public static applySettingsSnapshot(snapshot: string): void {
    if (snapshot.length === 0) {
      return;
    }
    let value: ImeSettings = SettingsStore.settings;
    let lines: Array<string> = snapshot.split('\n');
    for (let i: number = 0; i < lines.length; i++) {
      let line: string = lines[i];
      let splitIndex: number = line.indexOf('=');
      if (splitIndex <= 0) {
        continue;
      }
      let key: string = line.substring(0, splitIndex);
      let rawValue: string = line.substring(splitIndex + 1);
      let itemValue: string = SettingsStore.decodeSnapshotValue(rawValue);
      if (key === KEY_LAYOUT_MODE) {
        value.layoutMode = SettingsStore.snapshotToNumber(itemValue, value.layoutMode);
      } else if (key === KEY_KEYBOARD_HEIGHT_PERCENT) {
        value.keyboardHeightPercent =
          SettingsStore.clampKeyboardHeightPercent(SettingsStore.snapshotToNumber(itemValue, value.keyboardHeightPercent));
      } else if (key === KEY_KEYBOARD_DOCK_MODE) {
        value.keyboardDockMode =
          SettingsStore.clampKeyboardDockMode(SettingsStore.snapshotToNumber(itemValue, value.keyboardDockMode));
      } else if (key === KEY_NUMBER_ROW) {
        value.numberRowEnabled = SettingsStore.snapshotToBoolean(itemValue, value.numberRowEnabled);
      } else if (key === KEY_ENTER_SEND) {
        value.enterSendEnabled = SettingsStore.snapshotToBoolean(itemValue, value.enterSendEnabled);
      } else if (key === KEY_SWAP_LANG_NUMBER) {
        value.swapLangNumberEnabled = SettingsStore.snapshotToBoolean(itemValue, value.swapLangNumberEnabled);
      } else if (key === KEY_SWIPE_INPUT) {
        value.swipeInputEnabled = SettingsStore.snapshotToBoolean(itemValue, value.swipeInputEnabled);
      } else if (key === KEY_UPPER_CASE) {
        value.upperCaseEnabled = SettingsStore.snapshotToBoolean(itemValue, value.upperCaseEnabled);
      } else if (key === KEY_HAPTIC_STRENGTH) {
        value.hapticStrength = SettingsStore.snapshotToNumber(itemValue, value.hapticStrength);
      } else if (key === KEY_SOUND_VOLUME) {
        value.soundVolume = SettingsStore.snapshotToNumber(itemValue, value.soundVolume);
      } else if (key === KEY_SOUND_EFFECT) {
        value.soundEffectEnabled = SettingsStore.snapshotToBoolean(itemValue, value.soundEffectEnabled);
      } else if (key === KEY_KEY_POPUP) {
        value.keyPopupEnabled = SettingsStore.snapshotToBoolean(itemValue, value.keyPopupEnabled);
      } else if (key === KEY_KEY_FONT_SCALE) {
        value.keyFontScale =
          SettingsStore.clampKeyFontScale(SettingsStore.snapshotToNumber(itemValue, value.keyFontScale));
      } else if (key === KEY_LONG_PRESS_DELAY) {
        value.longPressDelay = SettingsStore.snapshotToNumber(itemValue, value.longPressDelay);
      } else if (key === KEY_SPEECH_INPUT) {
        value.speechInputEnabled = SettingsStore.snapshotToBoolean(itemValue, value.speechInputEnabled);
      } else if (key === KEY_FUZZY_PINYIN) {
        value.fuzzyPinyinEnabled = SettingsStore.snapshotToBoolean(itemValue, value.fuzzyPinyinEnabled);
      } else if (key === KEY_MIXED_INPUT) {
        value.mixedInputEnabled = SettingsStore.snapshotToBoolean(itemValue, value.mixedInputEnabled);
      } else if (key === KEY_SINGLE_CHAR_PRIORITY) {
        value.singleCharPriorityEnabled = SettingsStore.snapshotToBoolean(itemValue, value.singleCharPriorityEnabled);
      } else if (key === KEY_TRADITIONAL) {
        value.traditionalInputEnabled = SettingsStore.snapshotToBoolean(itemValue, value.traditionalInputEnabled);
      } else if (key === KEY_SYSTEM_MATERIAL_ENABLED) {
        value.systemMaterialEnabled = SettingsStore.snapshotToBoolean(itemValue, value.systemMaterialEnabled);
      } else if (key === KEY_SYSTEM_MATERIAL_LEVEL) {
        value.systemMaterialLevel = SettingsStore.snapshotToNumber(itemValue, value.systemMaterialLevel);
      } else if (key === KEY_SKIN_PRESET) {
        value.skinPreset = SettingsStore.snapshotToNumber(itemValue, value.skinPreset);
      } else if (key === KEY_SKIN_BACKGROUND_MODE) {
        value.skinBackgroundMode = SettingsStore.snapshotToNumber(itemValue, value.skinBackgroundMode);
      } else if (key === KEY_SKIN_BACKGROUND_COLOR) {
        value.skinBackgroundColor = itemValue;
      } else if (key === KEY_SKIN_KEY_COLOR) {
        value.skinKeyColor = itemValue;
      } else if (key === KEY_SKIN_IMAGE_URI) {
        value.skinImageUri = itemValue;
      } else if (key === KEY_SKIN_IMAGE_PATH) {
        value.skinImagePath = itemValue;
      } else if (key === KEY_SKIN_IMAGE_DATA_BASE64) {
        value.skinImageDataBase64 = itemValue;
      } else if (key === KEY_SKIN_IMAGE_REVISION) {
        value.skinImageRevision = itemValue;
      } else if (key === KEY_SKIN_IMAGE_AREA) {
        value.skinImageArea = SettingsStore.snapshotToNumber(itemValue, value.skinImageArea);
      } else if (key === KEY_SKIN_IMAGE_BLUR) {
        value.skinImageBlur =
          SettingsStore.clampSkinImageBlur(SettingsStore.snapshotToNumber(itemValue, value.skinImageBlur));
      }
    }
    SettingsStore.settings = value;
    SettingsStore.saveSettingsSnapshot(value);
    SettingsStore.publishSettings();
  }

  private static openPreferences(): void {
    if (SettingsStore.context === undefined) {
      return;
    }
    let context: common.Context = SettingsStore.context;
    let options: preferences.Options = SettingsStore.preferencesOptions();
    SettingsStore.prefs = undefined;
    try {
      preferences.removePreferencesFromCacheSync(context, options);
    } catch (e) {
      hilog.info(0x0000, TAG, 'preferences cache already clean');
    }
    SettingsStore.prefs = preferences.getPreferencesSync(context, options);
  }

  private static loadSettings(): void {
    let value: ImeSettings = new ImeSettings();
    if (SettingsStore.prefs !== undefined) {
      value.layoutMode = SettingsStore.readNumber(KEY_LAYOUT_MODE, KeyboardLayoutMode.QWERTY26);
      value.keyboardHeightPercent =
        SettingsStore.clampKeyboardHeightPercent(SettingsStore.readNumber(KEY_KEYBOARD_HEIGHT_PERCENT,
          KEYBOARD_HEIGHT_DEFAULT_PERCENT));
      value.keyboardDockMode =
        SettingsStore.clampKeyboardDockMode(SettingsStore.readNumber(KEY_KEYBOARD_DOCK_MODE, KeyboardDockMode.FULL));
      value.numberRowEnabled = SettingsStore.readBoolean(KEY_NUMBER_ROW, true);
      value.enterSendEnabled = SettingsStore.readBoolean(KEY_ENTER_SEND, false);
      value.swapLangNumberEnabled = SettingsStore.readBoolean(KEY_SWAP_LANG_NUMBER, false);
      value.swipeInputEnabled = SettingsStore.readBoolean(KEY_SWIPE_INPUT, false);
      value.upperCaseEnabled = SettingsStore.readBoolean(KEY_UPPER_CASE, false);
      value.hapticStrength = SettingsStore.readNumber(KEY_HAPTIC_STRENGTH, 45);
      value.soundVolume = SettingsStore.readNumber(KEY_SOUND_VOLUME, 0);
      value.soundEffectEnabled = SettingsStore.readBoolean(KEY_SOUND_EFFECT, false);
      value.keyPopupEnabled = SettingsStore.readBoolean(KEY_KEY_POPUP, true);
      value.keyFontScale =
        SettingsStore.clampKeyFontScale(SettingsStore.readNumber(KEY_KEY_FONT_SCALE, KEY_FONT_SCALE_DEFAULT));
      value.longPressDelay = SettingsStore.readNumber(KEY_LONG_PRESS_DELAY, 420);
      value.speechInputEnabled = SettingsStore.readBoolean(KEY_SPEECH_INPUT, false);
      value.fuzzyPinyinEnabled = SettingsStore.readBoolean(KEY_FUZZY_PINYIN, false);
      value.mixedInputEnabled = SettingsStore.readBoolean(KEY_MIXED_INPUT, true);
      value.singleCharPriorityEnabled = SettingsStore.readBoolean(KEY_SINGLE_CHAR_PRIORITY, true);
      value.traditionalInputEnabled = SettingsStore.readBoolean(KEY_TRADITIONAL, false);
      value.systemMaterialEnabled = SettingsStore.readBoolean(KEY_SYSTEM_MATERIAL_ENABLED, true);
      value.systemMaterialLevel =
        SettingsStore.clampSystemMaterialLevel(SettingsStore.readNumber(KEY_SYSTEM_MATERIAL_LEVEL,
          SystemMaterialLevelMode.REGULAR));
      value.skinPreset = SettingsStore.readNumber(KEY_SKIN_PRESET, KeyboardSkinPresetMode.LIQUID);
      value.skinBackgroundMode = SettingsStore.readNumber(KEY_SKIN_BACKGROUND_MODE, KeyboardSkinBackgroundMode.COLOR);
      value.skinBackgroundColor = SettingsStore.readString(KEY_SKIN_BACKGROUND_COLOR, '#FFF1F4F9');
      value.skinKeyColor = SettingsStore.readString(KEY_SKIN_KEY_COLOR, '#F2FFFFFF');
      value.skinImageUri = SettingsStore.readString(KEY_SKIN_IMAGE_URI, '');
      value.skinImagePath = SettingsStore.readString(KEY_SKIN_IMAGE_PATH, '');
      value.skinImageDataBase64 = SettingsStore.readImageDataBase64();
      value.skinImageRevision = SettingsStore.readString(KEY_SKIN_IMAGE_REVISION, '');
      value.skinImageArea = SettingsStore.readNumber(KEY_SKIN_IMAGE_AREA, KeyboardSkinImageAreaMode.CENTER);
      value.skinImageBlur =
        SettingsStore.clampSkinImageBlur(SettingsStore.readNumber(KEY_SKIN_IMAGE_BLUR, 0));
    }
    SettingsStore.settings = value;
  }

  private static publishSettings(): void {
    AppStorage.setOrCreate(KEY_LAYOUT_MODE, SettingsStore.settings.layoutMode);
    AppStorage.setOrCreate(KEY_KEYBOARD_HEIGHT_PERCENT,
      SettingsStore.clampKeyboardHeightPercent(SettingsStore.settings.keyboardHeightPercent));
    AppStorage.setOrCreate(KEY_KEYBOARD_DOCK_MODE,
      SettingsStore.clampKeyboardDockMode(SettingsStore.settings.keyboardDockMode));
    AppStorage.setOrCreate(KEY_NUMBER_ROW, SettingsStore.settings.numberRowEnabled);
    AppStorage.setOrCreate(KEY_ENTER_SEND, SettingsStore.settings.enterSendEnabled);
    AppStorage.setOrCreate(KEY_SWAP_LANG_NUMBER, SettingsStore.settings.swapLangNumberEnabled);
    AppStorage.setOrCreate(KEY_SWIPE_INPUT, SettingsStore.settings.swipeInputEnabled);
    AppStorage.setOrCreate(KEY_UPPER_CASE, SettingsStore.settings.upperCaseEnabled);
    AppStorage.setOrCreate(KEY_HAPTIC_STRENGTH, SettingsStore.settings.hapticStrength);
    AppStorage.setOrCreate(KEY_SOUND_VOLUME, SettingsStore.settings.soundVolume);
    AppStorage.setOrCreate(KEY_SOUND_EFFECT, SettingsStore.settings.soundEffectEnabled);
    AppStorage.setOrCreate(KEY_KEY_POPUP, SettingsStore.settings.keyPopupEnabled);
    AppStorage.setOrCreate(KEY_KEY_FONT_SCALE, SettingsStore.clampKeyFontScale(SettingsStore.settings.keyFontScale));
    AppStorage.setOrCreate(KEY_LONG_PRESS_DELAY, SettingsStore.settings.longPressDelay);
    AppStorage.setOrCreate(KEY_SPEECH_INPUT, SettingsStore.settings.speechInputEnabled);
    AppStorage.setOrCreate(KEY_FUZZY_PINYIN, SettingsStore.settings.fuzzyPinyinEnabled);
    AppStorage.setOrCreate(KEY_MIXED_INPUT, SettingsStore.settings.mixedInputEnabled);
    AppStorage.setOrCreate(KEY_SINGLE_CHAR_PRIORITY, SettingsStore.settings.singleCharPriorityEnabled);
    AppStorage.setOrCreate(KEY_TRADITIONAL, SettingsStore.settings.traditionalInputEnabled);
    AppStorage.setOrCreate(KEY_SYSTEM_MATERIAL_ENABLED, SettingsStore.settings.systemMaterialEnabled);
    AppStorage.setOrCreate(KEY_SYSTEM_MATERIAL_LEVEL, SettingsStore.settings.systemMaterialLevel);
    AppStorage.setOrCreate(KEY_SKIN_PRESET, SettingsStore.settings.skinPreset);
    AppStorage.setOrCreate(KEY_SKIN_BACKGROUND_MODE, SettingsStore.settings.skinBackgroundMode);
    AppStorage.setOrCreate(KEY_SKIN_BACKGROUND_COLOR, SettingsStore.settings.skinBackgroundColor);
    AppStorage.setOrCreate(KEY_SKIN_KEY_COLOR, SettingsStore.settings.skinKeyColor);
    AppStorage.setOrCreate(KEY_SKIN_IMAGE_URI, SettingsStore.settings.skinImageUri);
    AppStorage.setOrCreate(KEY_SKIN_IMAGE_PATH, SettingsStore.settings.skinImagePath);
    AppStorage.setOrCreate(KEY_SKIN_IMAGE_DATA_BASE64, SettingsStore.settings.skinImageDataBase64);
    AppStorage.setOrCreate(KEY_SKIN_IMAGE_REVISION, SettingsStore.settings.skinImageRevision);
    AppStorage.setOrCreate(KEY_SKIN_IMAGE_AREA, SettingsStore.settings.skinImageArea);
    AppStorage.setOrCreate(KEY_SKIN_IMAGE_BLUR, SettingsStore.settings.skinImageBlur);
    AppStorage.setOrCreate('ime.settingsReady', true);
  }

  private static readBoolean(key: string, defaultValue: boolean): boolean {
    if (SettingsStore.prefs === undefined) {
      return defaultValue;
    }
    try {
      let stored: preferences.ValueType = SettingsStore.prefs.getSync(key, defaultValue);
      return stored.toString() === 'true';
    } catch (e) {
      hilog.error(0x0000, TAG, 'read boolean failed');
    }
    return defaultValue;
  }

  private static clampKeyboardHeightPercent(value: number): number {
    if (value < KEYBOARD_HEIGHT_MIN_PERCENT) {
      return KEYBOARD_HEIGHT_MIN_PERCENT;
    }
    if (value > KEYBOARD_HEIGHT_MAX_PERCENT) {
      return KEYBOARD_HEIGHT_MAX_PERCENT;
    }
    return value;
  }

  private static clampKeyboardDockMode(value: number): number {
    if (value === KeyboardDockMode.LEFT || value === KeyboardDockMode.RIGHT) {
      return value;
    }
    return KeyboardDockMode.FULL;
  }

  private static clampKeyFontScale(value: number): number {
    if (value < KEY_FONT_SCALE_MIN) {
      return KEY_FONT_SCALE_MIN;
    }
    if (value > KEY_FONT_SCALE_MAX) {
      return KEY_FONT_SCALE_MAX;
    }
    return value;
  }

  private static clampSystemMaterialLevel(value: number): number {
    if (value === SystemMaterialLevelMode.ULTRA_THIN || value === SystemMaterialLevelMode.THIN ||
      value === SystemMaterialLevelMode.REGULAR || value === SystemMaterialLevelMode.THICK ||
      value === SystemMaterialLevelMode.ULTRA_THICK) {
      return value;
    }
    return SystemMaterialLevelMode.REGULAR;
  }

  private static clampSkinImageBlur(value: number): number {
    if (value < SKIN_IMAGE_BLUR_MIN) {
      return SKIN_IMAGE_BLUR_MIN;
    }
    if (value > SKIN_IMAGE_BLUR_MAX) {
      return SKIN_IMAGE_BLUR_MAX;
    }
    return value;
  }

  private static readNumber(key: string, defaultValue: number): number {
    if (SettingsStore.prefs === undefined) {
      return defaultValue;
    }
    try {
      let stored: preferences.ValueType = SettingsStore.prefs.getSync(key, defaultValue);
      let parsed: number = parseInt(stored.toString());
      if (Number.isNaN(parsed)) {
        return defaultValue;
      }
      return parsed;
    } catch (e) {
      hilog.error(0x0000, TAG, 'read number failed');
    }
    return defaultValue;
  }

  private static readString(key: string, defaultValue: string): string {
    if (SettingsStore.prefs === undefined) {
      return defaultValue;
    }
    try {
      let stored: preferences.ValueType = SettingsStore.prefs.getSync(key, defaultValue);
      return stored.toString();
    } catch (e) {
      hilog.error(0x0000, TAG, 'read string failed');
    }
    return defaultValue;
  }

  private static imageDataChunkKey(index: number): string {
    return KEY_SKIN_IMAGE_DATA_CHUNK_PREFIX + index.toString();
  }

  private static readImageDataBase64(): string {
    let chunkCount: number = SettingsStore.readNumber(KEY_SKIN_IMAGE_DATA_CHUNK_COUNT, 0);
    if (chunkCount > 0) {
      let packed: string = '';
      for (let i: number = 0; i < chunkCount; i++) {
        packed = packed + SettingsStore.readString(SettingsStore.imageDataChunkKey(i), '');
      }
      if (packed.length > 0) {
        return packed;
      }
    }
    return SettingsStore.readString(KEY_SKIN_IMAGE_DATA_BASE64, '');
  }

  private static saveImageDataBase64(value: string): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    try {
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_DATA_BASE64, '');
      let chunkCount: number = 0;
      if (value.length > 0) {
        chunkCount = Math.ceil(value.length / SKIN_IMAGE_DATA_CHUNK_SIZE);
      }
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_DATA_CHUNK_COUNT, chunkCount);
      for (let i: number = 0; i < chunkCount; i++) {
        let start: number = i * SKIN_IMAGE_DATA_CHUNK_SIZE;
        let end: number = start + SKIN_IMAGE_DATA_CHUNK_SIZE;
        if (end > value.length) {
          end = value.length;
        }
        SettingsStore.prefs.putSync(SettingsStore.imageDataChunkKey(i), value.substring(start, end));
      }
      SettingsStore.prefs.flushSync();
    } catch (e) {
      hilog.error(0x0000, TAG, 'save skin image data chunks failed');
    }
  }

  private static saveBoolean(key: string, value: boolean): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    try {
      SettingsStore.prefs.putSync(key, value);
      SettingsStore.prefs.flushSync();
    } catch (e) {
      hilog.error(0x0000, TAG, 'save boolean failed');
    }
  }

  private static saveNumber(key: string, value: number): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    try {
      SettingsStore.prefs.putSync(key, value);
      SettingsStore.prefs.flushSync();
    } catch (e) {
      hilog.error(0x0000, TAG, 'save number failed');
    }
  }

  private static saveString(key: string, value: string): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    try {
      SettingsStore.prefs.putSync(key, value);
      SettingsStore.prefs.flushSync();
    } catch (e) {
      hilog.error(0x0000, TAG, 'save string failed');
    }
  }

  private static nextRevision(size: number): string {
    return new Date().getTime().toString() + '_' + size.toString();
  }

  private static encodeImageData(value: Uint8Array): string {
    if (value.length === 0) {
      return '';
    }
    try {
      let base64: util.Base64Helper = new util.Base64Helper();
      return base64.encodeToStringSync(value);
    } catch (e) {
      hilog.error(0x0000, TAG, 'encode skin image data failed');
    }
    return '';
  }

  private static decodeImageData(value: string): Uint8Array {
    if (value.length === 0) {
      return new Uint8Array(0);
    }
    try {
      let base64: util.Base64Helper = new util.Base64Helper();
      return base64.decodeSync(value);
    } catch (e) {
      hilog.error(0x0000, TAG, 'decode skin image data failed');
    }
    return new Uint8Array(0);
  }

  private static imageBufferFromBytes(data: Uint8Array): ArrayBuffer {
    let buffer: ArrayBuffer = new ArrayBuffer(data.length);
    let target: Uint8Array = new Uint8Array(buffer);
    for (let i: number = 0; i < data.length; i++) {
      target[i] = data[i];
    }
    return buffer;
  }

  private static writeSharedSkinImageFile(data: Uint8Array): string {
    if (SettingsStore.context === undefined || data.length === 0) {
      return '';
    }
    let imagePath: string = SettingsStore.context.filesDir + '/' + SKIN_IMAGE_FILE_NAME;
    let imageFile: fileIo.File | undefined = undefined;
    try {
      imageFile = fileIo.openSync(imagePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE |
        fileIo.OpenMode.TRUNC);
      fileIo.writeSync(imageFile.fd, SettingsStore.imageBufferFromBytes(data));
      return imagePath;
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0x0000, TAG, 'write shared skin image file failed: %{public}d %{public}s', err.code, err.message);
    } finally {
      if (imageFile !== undefined) {
        fileIo.closeSync(imageFile);
      }
    }
    return '';
  }

  private static saveSettingsSnapshot(value: ImeSettings): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    try {
      SettingsStore.prefs.putSync(KEY_LAYOUT_MODE, value.layoutMode);
      SettingsStore.prefs.putSync(KEY_KEYBOARD_HEIGHT_PERCENT,
        SettingsStore.clampKeyboardHeightPercent(value.keyboardHeightPercent));
      SettingsStore.prefs.putSync(KEY_KEYBOARD_DOCK_MODE, SettingsStore.clampKeyboardDockMode(value.keyboardDockMode));
      SettingsStore.prefs.putSync(KEY_NUMBER_ROW, value.numberRowEnabled);
      SettingsStore.prefs.putSync(KEY_ENTER_SEND, value.enterSendEnabled);
      SettingsStore.prefs.putSync(KEY_SWAP_LANG_NUMBER, value.swapLangNumberEnabled);
      SettingsStore.prefs.putSync(KEY_SWIPE_INPUT, value.swipeInputEnabled);
      SettingsStore.prefs.putSync(KEY_UPPER_CASE, value.upperCaseEnabled);
      SettingsStore.prefs.putSync(KEY_HAPTIC_STRENGTH, value.hapticStrength);
      SettingsStore.prefs.putSync(KEY_SOUND_VOLUME, value.soundVolume);
      SettingsStore.prefs.putSync(KEY_SOUND_EFFECT, value.soundEffectEnabled);
      SettingsStore.prefs.putSync(KEY_KEY_POPUP, value.keyPopupEnabled);
      SettingsStore.prefs.putSync(KEY_KEY_FONT_SCALE, SettingsStore.clampKeyFontScale(value.keyFontScale));
      SettingsStore.prefs.putSync(KEY_LONG_PRESS_DELAY, value.longPressDelay);
      SettingsStore.prefs.putSync(KEY_SPEECH_INPUT, value.speechInputEnabled);
      SettingsStore.prefs.putSync(KEY_FUZZY_PINYIN, value.fuzzyPinyinEnabled);
      SettingsStore.prefs.putSync(KEY_MIXED_INPUT, value.mixedInputEnabled);
      SettingsStore.prefs.putSync(KEY_SINGLE_CHAR_PRIORITY, value.singleCharPriorityEnabled);
      SettingsStore.prefs.putSync(KEY_TRADITIONAL, value.traditionalInputEnabled);
      SettingsStore.prefs.putSync(KEY_SYSTEM_MATERIAL_ENABLED, value.systemMaterialEnabled);
      SettingsStore.prefs.putSync(KEY_SYSTEM_MATERIAL_LEVEL, value.systemMaterialLevel);
      SettingsStore.prefs.putSync(KEY_SKIN_PRESET, value.skinPreset);
      SettingsStore.prefs.putSync(KEY_SKIN_BACKGROUND_MODE, value.skinBackgroundMode);
      SettingsStore.prefs.putSync(KEY_SKIN_BACKGROUND_COLOR, value.skinBackgroundColor);
      SettingsStore.prefs.putSync(KEY_SKIN_KEY_COLOR, value.skinKeyColor);
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_URI, value.skinImageUri);
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_PATH, value.skinImagePath);
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_REVISION, value.skinImageRevision);
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_AREA, value.skinImageArea);
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_BLUR, SettingsStore.clampSkinImageBlur(value.skinImageBlur));
      SettingsStore.prefs.flushSync();
    } catch (e) {
      hilog.error(0x0000, TAG, 'save settings snapshot failed');
    }
    SettingsStore.saveImageDataBase64(value.skinImageDataBase64);
  }

  private static saveSkinImageState(uri: string, path: string, dataBase64: string, revision: string): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    try {
      SettingsStore.prefs.putSync(KEY_SKIN_PRESET, KeyboardSkinPresetMode.CUSTOM);
      SettingsStore.prefs.putSync(KEY_SKIN_BACKGROUND_MODE, KeyboardSkinBackgroundMode.IMAGE);
      SettingsStore.prefs.putSync(KEY_SKIN_KEY_COLOR, '#88FFFFFF');
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_URI, uri);
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_PATH, path);
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_REVISION, revision);
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_BLUR, 0);
      SettingsStore.prefs.flushSync();
    } catch (e) {
      hilog.error(0x0000, TAG, 'save skin image state failed');
    }
    SettingsStore.saveImageDataBase64(dataBase64);
  }

  private static saveClearedSkinImageState(revision: string): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    try {
      SettingsStore.prefs.putSync(KEY_SKIN_BACKGROUND_MODE, KeyboardSkinBackgroundMode.COLOR);
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_URI, '');
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_PATH, '');
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_DATA_BASE64, '');
      SettingsStore.prefs.putSync(KEY_SKIN_IMAGE_REVISION, revision);
      SettingsStore.prefs.flushSync();
    } catch (e) {
      hilog.error(0x0000, TAG, 'clear skin image state failed');
    }
  }

  private static publishKeyboardHeightChanged(value: number): void {
    let eventData: commonEventManager.CommonEventPublishData = {
      data: value.toString()
    };
    try {
      commonEventManager.publish(EVENT_KEYBOARD_HEIGHT_CHANGED, eventData, (err: BusinessError) => {
        if (err) {
          hilog.error(0x0000, TAG, 'publish keyboard height event failed: %{public}d %{public}s',
            err.code, err.message);
        }
      });
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'publish keyboard height event err: %{public}d %{public}s',
        err.code, err.message);
    }
  }

  private static publishSettingsChanged(): void {
    let eventData: commonEventManager.CommonEventPublishData = {
      data: SettingsStore.buildSettingsSnapshot()
    };
    try {
      commonEventManager.publish(EVENT_SETTINGS_CHANGED, eventData, (err: BusinessError) => {
        if (err) {
          hilog.error(0x0000, TAG, 'publish settings event failed: %{public}d %{public}s',
            err.code, err.message);
        }
      });
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'publish settings event err: %{public}d %{public}s',
        err.code, err.message);
    }
  }

  private static loadRecentWords(): void {
    SettingsStore.recentWords = [];
    if (SettingsStore.prefs === undefined) {
      return;
    }
    let packed: string = '';
    try {
      let stored: preferences.ValueType = SettingsStore.prefs.getSync(KEY_RECENT_WORDS, '');
      packed = stored.toString();
    } catch (e) {
      hilog.error(0x0000, TAG, 'read recent words failed');
      return;
    }
    if (packed.length === 0) {
      return;
    }
    let rows: Array<string> = packed.split('|');
    for (let i: number = 0; i < rows.length; i++) {
      let row: string = rows[i];
      let parts: Array<string> = row.split(':');
      if (parts.length >= 2) {
        let score: number = parseInt(parts[1]);
        if (!Number.isNaN(score)) {
          SettingsStore.recentWords.push(new RecentWord(parts[0], score));
        }
      }
    }
  }

  private static saveRecentWords(): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    let parts: Array<string> = [];
    for (let i: number = 0; i < SettingsStore.recentWords.length; i++) {
      let item: RecentWord = SettingsStore.recentWords[i];
      parts.push(item.word + ':' + item.score.toString());
    }
    try {
      SettingsStore.prefs.putSync(KEY_RECENT_WORDS, parts.join('|'));
      SettingsStore.prefs.flush((err: BusinessError) => {
        if (err) {
          hilog.error(0x0000, TAG, 'flush recent words failed');
        }
      });
    } catch (e) {
      hilog.error(0x0000, TAG, 'save recent words failed');
    }
  }

  private static loadClipboardHistory(): void {
    SettingsStore.clipboardHistory = [];
    if (SettingsStore.prefs === undefined) {
      return;
    }
    let packed: string = SettingsStore.readString(KEY_CLIPBOARD_HISTORY, '');
    if (packed.length === 0) {
      return;
    }
    let rows: Array<string> = packed.split('\n');
    for (let i: number = 0; i < rows.length; i++) {
      let row: string = rows[i];
      let splitIndex: number = row.indexOf('=');
      if (splitIndex <= 0) {
        continue;
      }
      let createdAt: number = parseInt(row.substring(0, splitIndex));
      if (Number.isNaN(createdAt)) {
        continue;
      }
      let encodedText: string = row.substring(splitIndex + 1);
      let text: string = SettingsStore.decodeSnapshotValue(encodedText);
      if (text.trim().length > 0 && text.length <= CLIPBOARD_HISTORY_MAX_ITEM_LENGTH) {
        SettingsStore.clipboardHistory.push(new ClipboardHistoryItem(text, createdAt));
      }
    }
    SettingsStore.pruneClipboardHistory();
  }

  private static pruneClipboardHistory(): void {
    let totalLength: number = 0;
    let retained: Array<ClipboardHistoryItem> = [];
    for (let i: number = 0; i < SettingsStore.clipboardHistory.length; i++) {
      if (retained.length >= CLIPBOARD_HISTORY_MAX_ITEMS) {
        break;
      }
      let item: ClipboardHistoryItem = SettingsStore.clipboardHistory[i];
      if (retained.length > 0 && totalLength + item.text.length > CLIPBOARD_HISTORY_MAX_TOTAL_LENGTH) {
        break;
      }
      retained.push(item);
      totalLength = totalLength + item.text.length;
    }
    SettingsStore.clipboardHistory = retained;
  }

  private static saveClipboardHistory(): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    let rows: Array<string> = [];
    for (let i: number = 0; i < SettingsStore.clipboardHistory.length; i++) {
      let item: ClipboardHistoryItem = SettingsStore.clipboardHistory[i];
      rows.push(item.createdAt.toString() + '=' + encodeURIComponent(item.text));
    }
    try {
      SettingsStore.prefs.putSync(KEY_CLIPBOARD_HISTORY, rows.join('\n'));
      SettingsStore.prefs.flushSync();
    } catch (e) {
      hilog.error(0x0000, TAG, 'save clipboard history failed');
    }
  }

  private static loadRecentEmoji(): void {
    SettingsStore.recentEmoji = [];
    if (SettingsStore.prefs === undefined) {
      return;
    }
    let packed: string = SettingsStore.readString(KEY_RECENT_EMOJI, '');
    if (packed.length === 0) {
      return;
    }
    let rows: Array<string> = packed.split('\n');
    for (let i: number = 0; i < rows.length && SettingsStore.recentEmoji.length < RECENT_EMOJI_MAX_ITEMS; i++) {
      let value: string = SettingsStore.decodeSnapshotValue(rows[i]);
      if (value.trim().length > 0 && !SettingsStore.containsRecentEmoji(value)) {
        SettingsStore.recentEmoji.push(value);
      }
    }
  }

  private static containsRecentEmoji(value: string): boolean {
    for (let i: number = 0; i < SettingsStore.recentEmoji.length; i++) {
      if (SettingsStore.recentEmoji[i] === value) {
        return true;
      }
    }
    return false;
  }

  private static saveRecentEmoji(): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    let rows: Array<string> = [];
    for (let i: number = 0; i < SettingsStore.recentEmoji.length; i++) {
      rows.push(encodeURIComponent(SettingsStore.recentEmoji[i]));
    }
    try {
      SettingsStore.prefs.putSync(KEY_RECENT_EMOJI, rows.join('\n'));
      SettingsStore.prefs.flushSync();
    } catch (e) {
      hilog.error(0x0000, TAG, 'save recent emoji failed');
    }
  }
}
