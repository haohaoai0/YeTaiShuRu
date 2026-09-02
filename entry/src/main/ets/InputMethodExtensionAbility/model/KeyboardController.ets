import { Want } from '@kit.AbilityKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { inputMethod, inputMethodEngine, InputMethodExtensionContext, InputMethodSubtype } from '@kit.IMEKit';
import { display } from '@kit.ArkUI';
import { KeyCode } from '@kit.InputKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { InputFeedback } from '../../common/InputFeedback';
import { SoundFeedback } from '../../common/SoundFeedback';
import { voiceInputManager } from '../../common/VoiceInputManager';
import { HardKeyUtils } from '../../model/HardKeyUtils';
import { KeyboardLayoutMode, KeyboardSkinPresetMode, SettingsStore } from '../../model/ImeSettings';
import { SETTINGS_LAUNCH_PARAM_ROUTE } from '../../model/SettingsLaunch';
import { pinyinEngine } from '../../model/PinyinEngine';

const TAG: string = 'KeyboardController';
const PERCENT_BASE: number = 100;
const SUBTYPE_EN_ID: string = 'LiquidIME_EN';
const SUBTYPE_ZH_ID: string = 'LiquidIME_ZH';
const SUBTYPE_STORAGE_EN: string = 'EN';
const SUBTYPE_STORAGE_ZH: string = 'ZH';
const STORAGE_SECURITY_MODE: string = 'ime.securityMode';
const STORAGE_SECURITY_MODE_BASIC: string = 'ime.securityModeBasic';
const STORAGE_IMMERSIVE_MODE: string = 'ime.immersiveMode';

const inputMethodAbility: inputMethodEngine.InputMethodAbility = inputMethodEngine.getInputMethodAbility();

/**
 * 封装与编辑器交互的所有操作（插入/删除/光标移动等）。
 * Index.ets 中的按键回调会通过 InputHandler.getInstance() 调用这些方法。
 */
export class InputHandler {
  private kbController: inputMethodEngine.KeyboardController | undefined = undefined;
  private textInputClient: inputMethodEngine.InputClient | undefined = undefined;
  private editorAttribute: inputMethodEngine.EditorAttribute | undefined = undefined;

  private constructor() {
  }

  public static getInstance(): InputHandler {
    let instance = AppStorage.get<InputHandler>('inputHandler');
    if (instance === undefined) {
      instance = new InputHandler();
      AppStorage.setOrCreate('inputHandler', instance);
    }
    return instance;
  }

  public onInputStart(kbController: inputMethodEngine.KeyboardController,
                      textInputClient: inputMethodEngine.InputClient): void {
    this.kbController = kbController;
    this.textInputClient = textInputClient;
    this.textInputClient.getEditorAttribute().then((res: inputMethodEngine.EditorAttribute) => {
      this.updateEditorAttribute(res);
      hilog.info(0x0000, TAG,
        'onInputStart enterKeyType=%{public}d, inputPattern=%{public}d', res.enterKeyType, res.inputPattern);
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'getEditorAttribute err: %{public}d %{public}s', err.code, err.message);
    });
  }

  public updateEditorAttribute(attr: inputMethodEngine.EditorAttribute): void {
    this.editorAttribute = attr;
    AppStorage.setOrCreate('enterKeyType', attr.enterKeyType);
    AppStorage.setOrCreate('inputPattern', attr.inputPattern);
  }

  public hideKeyboardSelf(): void {
    pinyinEngine.clear();
    if (this.kbController === undefined) {
      return;
    }
    this.kbController.hide().then(() => {
      hilog.info(0x0000, TAG, 'hideKeyboardSelf success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'hideKeyboardSelf err: %{public}d %{public}s', err.code, err.message);
    });
  }

  public insertText(text: string): void {
    if (this.textInputClient === undefined) {
      return;
    }
    try {
      this.textInputClient.insertTextSync(text);
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'insertText err: %{public}d %{public}s', err.code, err.message);
    }
  }

  public insertExternalText(text: string): void {
    if (text.length === 0) {
      return;
    }
    this.triggerFeedback();
    if (pinyinEngine.hasComposition()) {
      this.commitCompositionCandidate(0);
    }
    this.insertText(text);
  }

  public inputLetter(text: string): void {
    this.triggerFeedback();
    let layoutMode: number = this.currentLayoutMode();
    if (this.isChineseSubtype() && (layoutMode === KeyboardLayoutMode.QWERTY26 ||
      layoutMode === KeyboardLayoutMode.XIAOHE_SHUANGPIN)) {
      pinyinEngine.inputCode(text, layoutMode);
      return;
    }
    this.insertText(text);
  }

  public inputT9Digit(digit: string): void {
    this.triggerFeedback();
    if (this.isChineseSubtype()) {
      pinyinEngine.inputCode(digit, KeyboardLayoutMode.T9);
      return;
    }
    this.insertText(digit);
  }

  public inputPunctuation(text: string): void {
    this.triggerFeedback();
    if (pinyinEngine.hasComposition()) {
      this.commitCompositionCandidate(0);
    }
    this.insertText(text);
  }

  public inputSpace(): void {
    this.triggerFeedback();
    if (pinyinEngine.hasComposition()) {
      this.commitCompositionCandidate(0);
      return;
    }
    this.insertText(' ');
  }

  public selectCandidate(index: number): void {
    this.triggerFeedback();
    this.commitCompositionCandidate(index);
  }

  public deleteSmart(): void {
    this.triggerFeedback();
    if (pinyinEngine.removeLast(this.currentLayoutMode())) {
      return;
    }
    this.deleteForward(1);
  }

  public deleteForward(length: number): void {
    if (this.textInputClient === undefined) {
      return;
    }
    this.textInputClient.deleteForward(length).then(() => {
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'deleteForward err: %{public}d %{public}s', err.code, err.message);
    });
  }

  public deleteBackward(length: number): void {
    if (this.textInputClient === undefined) {
      return;
    }
    this.textInputClient.deleteBackward(length).then(() => {
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'deleteBackward err: %{public}d %{public}s', err.code, err.message);
    });
  }

  public sendEnterKey(): void {
    this.triggerFeedback();
    if (pinyinEngine.hasComposition()) {
      this.commitCompositionCandidate(0);
      return;
    }
    if (this.textInputClient === undefined || this.editorAttribute === undefined) {
      return;
    }
    this.textInputClient.sendKeyFunction(this.editorAttribute.enterKeyType).then(() => {
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'sendKeyFunction err: %{public}d %{public}s', err.code, err.message);
    });
  }

  public moveCursor(direction: inputMethodEngine.Direction): void {
    if (this.textInputClient === undefined) {
      return;
    }
    this.textInputClient.moveCursor(direction).then(() => {
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'moveCursor err: %{public}d %{public}s', err.code, err.message);
    });
  }

  private commitCompositionCandidate(index: number): void {
    let text: string = pinyinEngine.commitCandidate(index);
    if (text.length > 0) {
      this.insertText(text);
    }
  }

  private isChineseSubtype(): boolean {
    let subtype: string | undefined = AppStorage.get<string>('subtypeId');
    return subtype === SUBTYPE_STORAGE_ZH;
  }

  private currentLayoutMode(): number {
    let layoutMode: number | undefined = AppStorage.get<number>('ime.layoutMode');
    if (layoutMode === undefined) {
      return SettingsStore.getLayoutMode();
    }
    return layoutMode;
  }

  private triggerFeedback(): void {
    let strength: number | undefined = AppStorage.get<number>('ime.hapticStrength');
    if (strength === undefined) {
      strength = 45;
    }
    InputFeedback.triggerKey(strength);
    let soundEnabled: boolean | undefined = AppStorage.get<boolean>('ime.soundEffect');
    let soundVolume: number | undefined = AppStorage.get<number>('ime.soundVolume');
    if (soundEnabled === undefined) {
      soundEnabled = false;
    }
    if (soundVolume === undefined) {
      soundVolume = 0;
    }
    SoundFeedback.play(soundEnabled, soundVolume);
  }
}

/**
 * KeyboardController：负责创建/销毁 Panel，注册输入法事件监听。
 */
class KeyboardController {
  private context: InputMethodExtensionContext | undefined = undefined;
  private panel: inputMethodEngine.Panel | undefined = undefined;
  private keyboardDelegate: inputMethodEngine.KeyboardDelegate | undefined = undefined;
  private inputHandler: InputHandler = InputHandler.getInstance();
  private inputStopCallback: () => void = () => {};
  private displayWidth: number = 0;
  private displayHeight: number = 0;
  private settingsSubscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  private hardKeyCodes: Array<number> = [];
  private editorAttributeChangedCallback: (attr: inputMethodEngine.EditorAttribute) => void =
    (attr: inputMethodEngine.EditorAttribute): void => {};
  private securityModeChangeCallback: (mode: inputMethodEngine.SecurityMode) => void =
    (mode: inputMethodEngine.SecurityMode): void => {};

  public onCreate(context: InputMethodExtensionContext): void {
    this.context = context;
    SettingsStore.init(context);
    SoundFeedback.init(context.resourceManager);
    voiceInputManager.initialize();
    voiceInputManager.setResultCallback((text: string): void => {
      this.inputHandler.insertText(text);
    });
    this.syncSecurityMode();
    this.syncCurrentSubtype();
    this.subscribeSettingsEvents();
    this.initWindow();
    this.registerListener();
    pinyinEngine.loadFromResource(context.resourceManager);
  }

  public onDestroy(): void {
    voiceInputManager.shutdown();
    this.unsubscribeSettingsEvents();
    this.unregisterListener();
    this.destroyPanel();
    if (this.context !== undefined) {
      this.context.destroy();
    }
  }

  public resizeKeyboardPanel(): void {
    if (this.panel === undefined || this.displayWidth <= 0 || this.displayHeight <= 0) {
      return;
    }
    let panelHeight: number = this.panelHeight();
    this.panel.resize(this.displayWidth, panelHeight).then(() => {
      hilog.info(0x0000, TAG, 'resize panel height=%{public}d', panelHeight);
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'resize panel err: %{public}d %{public}s', err.code, err.message);
    });
  }

  public openSettings(route: string): void {
    if (this.context === undefined) {
      return;
    }
    let parameters: Record<string, Object> = {};
    parameters[SETTINGS_LAUNCH_PARAM_ROUTE] = route;
    let want: Want = {
      bundleName: this.context.applicationInfo.name,
      abilityName: 'EntryAbility',
      parameters: parameters
    };
    this.context.startAbility(want).then(() => {
      hilog.info(0x0000, TAG, 'open settings success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'open settings err: %{public}d %{public}s', err.code, err.message);
    });
  }

  public switchSubtype(): void {
    let currentSubtypeId: string = this.currentSubtypeId();
    let targetSubtypeId: string = SUBTYPE_ZH_ID;
    if (currentSubtypeId === SUBTYPE_ZH_ID) {
      targetSubtypeId = SUBTYPE_EN_ID;
    } else if (currentSubtypeId !== SUBTYPE_EN_ID) {
      let storageSubtypeId: string | undefined = AppStorage.get<string>('subtypeId');
      if (storageSubtypeId === SUBTYPE_STORAGE_ZH) {
        targetSubtypeId = SUBTYPE_EN_ID;
      }
    }
    this.switchCurrentSubtypeById(targetSubtypeId).then((switched: boolean) => {
      if (!switched) {
        hilog.error(0x0000, TAG, 'switchSubtype failed, target=%{public}s', targetSubtypeId);
      }
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'switchSubtype err: %{public}d %{public}s', err.code, err.message);
    });
  }

  public async switchCurrentSubtypeById(targetSubtypeId: string): Promise<boolean> {
    try {
      let subtypes: Array<InputMethodSubtype> = await inputMethod.getSetting().listCurrentInputMethodSubtype();
      for (let i: number = 0; i < subtypes.length; i++) {
        let subtype: InputMethodSubtype = subtypes[i];
        if (subtype.id === targetSubtypeId) {
          let switched: boolean = await inputMethod.switchCurrentInputMethodSubtype(subtype);
          if (switched) {
            this.applySubtype(subtype);
          }
          return switched;
        }
      }
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'switchCurrentSubtypeById err: %{public}d %{public}s', err.code, err.message);
    }
    return false;
  }

  public async switchToNextInputMethod(): Promise<boolean> {
    try {
      let inputMethods: Array<inputMethod.InputMethodProperty> =
        await inputMethod.getSetting().getInputMethods(true);
      let currentInputMethod: inputMethod.InputMethodProperty = inputMethod.getCurrentInputMethod();
      for (let i: number = 0; i < inputMethods.length; i++) {
        let item: inputMethod.InputMethodProperty = inputMethods[i];
        if (!this.isSameInputMethod(item, currentInputMethod)) {
          return await inputMethod.switchInputMethod(item);
        }
      }
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'switchToNextInputMethod err: %{public}d %{public}s', err.code, err.message);
    }
    return false;
  }

  private initWindow(): void {
    if (this.context === undefined) {
      return;
    }
    let dis: display.Display | undefined = undefined;
    try {
      dis = display.getDefaultDisplaySync();
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'getDefaultDisplaySync err: %{public}d %{public}s', err.code, err.message);
      return;
    }
    if (dis === undefined) {
      return;
    }
    this.displayWidth = dis.width;
    this.displayHeight = dis.height;
    let isLandscape: boolean = this.displayWidth > this.displayHeight;
    AppStorage.setOrCreate('windowWidth', this.displayWidth);
    AppStorage.setOrCreate('windowHeight', this.displayHeight);
    AppStorage.setOrCreate('isLandscape', isLandscape);
    AppStorage.setOrCreate('ime.panelSettingsVisible', false);

    let keyHeight: number = this.panelHeight();

    let panelInfo: inputMethodEngine.PanelInfo = {
      type: inputMethodEngine.PanelType.SOFT_KEYBOARD,
      flag: inputMethodEngine.PanelFlag.FLG_FIXED
    };

    inputMethodAbility.createPanel(this.context, panelInfo).then((panel: inputMethodEngine.Panel) => {
      this.panel = panel;
      this.setPanelImmersiveMode(this.currentPanelImmersiveMode());
      panel.resize(this.displayWidth, keyHeight).then(() => {
        panel.setUiContent('InputMethodExtensionAbility/pages/Index').then(() => {
          hilog.info(0x0000, TAG, 'setUiContent success');
        }).catch((err: BusinessError) => {
          hilog.error(0x0000, TAG, 'setUiContent err: %{public}d %{public}s', err.code, err.message);
        });
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, TAG, 'panel.resize err: %{public}d %{public}s', err.code, err.message);
      });
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'createPanel err: %{public}d %{public}s', err.code, err.message);
    });
  }

  private panelHeight(): number {
    let heightPercent: number = SettingsStore.getKeyboardHeightPercent();
    return Math.floor(this.displayHeight * heightPercent / PERCENT_BASE);
  }

  private subscribeSettingsEvents(): void {
    if (this.settingsSubscriber !== undefined) {
      return;
    }
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [SettingsStore.keyboardHeightChangedEvent(), SettingsStore.settingsChangedEvent()]
    };
    try {
      let subscriber: commonEventManager.CommonEventSubscriber = commonEventManager.createSubscriberSync(subscribeInfo);
      this.settingsSubscriber = subscriber;
      commonEventManager.subscribe(subscriber,
        (err: BusinessError, data: commonEventManager.CommonEventData) => {
          if (err) {
            hilog.error(0x0000, TAG, 'settings event err: %{public}d %{public}s', err.code, err.message);
            return;
          }
          this.handleSettingsEvent(data);
        });
    } catch (e) {
      let err = e as BusinessError;
      this.settingsSubscriber = undefined;
      hilog.error(0x0000, TAG, 'subscribe settings event err: %{public}d %{public}s', err.code, err.message);
    }
  }

  private handleSettingsEvent(data: commonEventManager.CommonEventData): void {
    if (data.event === SettingsStore.settingsChangedEvent()) {
      if (data.data !== undefined && data.data.length > 0) {
        SettingsStore.applySettingsSnapshot(data.data);
      } else {
        SettingsStore.reloadSettings();
      }
      return;
    }
    if (data.event !== SettingsStore.keyboardHeightChangedEvent()) {
      return;
    }
    if (data.data === undefined) {
      SettingsStore.reloadSettings();
      this.resizeKeyboardPanel();
      return;
    }
    let heightPercent: number = parseInt(data.data);
    if (Number.isNaN(heightPercent)) {
      SettingsStore.reloadSettings();
      this.resizeKeyboardPanel();
      return;
    }
    SettingsStore.applyKeyboardHeightPercent(heightPercent);
    this.resizeKeyboardPanel();
  }

  private unsubscribeSettingsEvents(): void {
    if (this.settingsSubscriber === undefined) {
      return;
    }
    let subscriber: commonEventManager.CommonEventSubscriber = this.settingsSubscriber;
    this.settingsSubscriber = undefined;
    try {
      commonEventManager.unsubscribe(subscriber, (err: BusinessError) => {
        if (err) {
          hilog.error(0x0000, TAG, 'unsubscribe settings event err: %{public}d %{public}s',
            err.code, err.message);
        }
      });
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'unsubscribe settings event failed: %{public}d %{public}s',
        err.code, err.message);
    }
  }

  private destroyPanel(): void {
    if (this.panel === undefined) {
      return;
    }
    inputMethodAbility.destroyPanel(this.panel).then(() => {
      hilog.info(0x0000, TAG, 'destroyPanel success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, 'destroyPanel err: %{public}d %{public}s', err.code, err.message);
    });
  }

  private registerListener(): void {
    inputMethodAbility.on('inputStart',
      (kbController: inputMethodEngine.KeyboardController, textInputClient: inputMethodEngine.InputClient) => {
        hilog.info(0x0000, TAG, 'inputStart');
        pinyinEngine.clear();
        SettingsStore.reloadSettings();
        this.resizeKeyboardPanel();
        this.inputHandler.onInputStart(kbController, textInputClient);
      });

    this.inputStopCallback = () => {
      hilog.info(0x0000, TAG, 'inputStop');
      this.onDestroy();
    };
    inputMethodAbility.on('inputStop', this.inputStopCallback);

    // 监听子类型切换（中/英 切换）
    inputMethodAbility.on('setSubtype', (subtype: InputMethodSubtype) => {
      hilog.info(0x0000, TAG, 'setSubtype: %{public}s', subtype.id);
      this.applySubtype(subtype);
    });

    this.securityModeChangeCallback = (mode: inputMethodEngine.SecurityMode) => {
      this.applySecurityMode(mode);
    };
    inputMethodAbility.on('securityModeChange', this.securityModeChangeCallback);

    // 物理键盘按键监听
    this.keyboardDelegate = inputMethodEngine.getKeyboardDelegate();
    this.editorAttributeChangedCallback = (attr: inputMethodEngine.EditorAttribute) => {
      this.handleEditorAttributeChanged(attr);
    };
    this.keyboardDelegate.on('editorAttributeChanged', this.editorAttributeChangedCallback);
    this.keyboardDelegate.on('keyDown', (keyEvent: inputMethodEngine.KeyEvent) => {
      hilog.info(0x0000, TAG, 'keyDown code=%{public}d', keyEvent.keyCode);
      return this.handleHardKeyDown(keyEvent);
    });

    this.keyboardDelegate.on('keyUp', (keyEvent: inputMethodEngine.KeyEvent) => {
      return this.handleHardKeyUp(keyEvent);
    });
  }

  private handleHardKeyDown(keyEvent: inputMethodEngine.KeyEvent): boolean {
    let keyCode: number = keyEvent.keyCode;
    if (this.hardKeyCodes.indexOf(keyCode) < 0) {
      this.hardKeyCodes.push(keyCode);
    }
    if (HardKeyUtils.isShiftKey(keyCode) || HardKeyUtils.isAltKey(keyCode)) {
      return false;
    }
    if (this.handleHardFunctionKey(keyCode)) {
      return true;
    }
    let text: string = HardKeyUtils.getTextValue(keyCode, this.isHardShiftPressed());
    if (text.length === 0) {
      return false;
    }
    if (HardKeyUtils.isLetterKey(keyCode)) {
      this.inputHandler.inputLetter(text);
      return true;
    }
    if (HardKeyUtils.isDigitText(text) && pinyinEngine.hasComposition()) {
      let candidateIndex: number = parseInt(text) - 1;
      if (candidateIndex >= 0) {
        this.inputHandler.selectCandidate(candidateIndex);
        return true;
      }
    }
    this.inputHandler.inputPunctuation(text);
    return true;
  }

  private handleHardKeyUp(keyEvent: inputMethodEngine.KeyEvent): boolean {
    let keyCode: number = keyEvent.keyCode;
    let index: number = this.hardKeyCodes.indexOf(keyCode);
    if (index >= 0) {
      this.hardKeyCodes.splice(index, 1);
    }
    if (HardKeyUtils.isShiftKey(keyCode) || HardKeyUtils.isAltKey(keyCode)) {
      return false;
    }
    if (this.isHardRecognizedKey(keyCode)) {
      return true;
    }
    return false;
  }

  private handleHardFunctionKey(keyCode: number): boolean {
    if (keyCode === KeyCode.KEYCODE_DEL) {
      this.inputHandler.deleteSmart();
      return true;
    }
    if (keyCode === KeyCode.KEYCODE_ENTER) {
      this.inputHandler.sendEnterKey();
      return true;
    }
    if (keyCode === KeyCode.KEYCODE_SPACE) {
      this.inputHandler.inputSpace();
      return true;
    }
    if (keyCode === KeyCode.KEYCODE_DPAD_LEFT) {
      this.inputHandler.moveCursor(inputMethodEngine.Direction.CURSOR_LEFT);
      return true;
    }
    if (keyCode === KeyCode.KEYCODE_DPAD_RIGHT) {
      this.inputHandler.moveCursor(inputMethodEngine.Direction.CURSOR_RIGHT);
      return true;
    }
    if (keyCode === KeyCode.KEYCODE_DPAD_UP) {
      this.inputHandler.moveCursor(inputMethodEngine.Direction.CURSOR_UP);
      return true;
    }
    if (keyCode === KeyCode.KEYCODE_DPAD_DOWN) {
      this.inputHandler.moveCursor(inputMethodEngine.Direction.CURSOR_DOWN);
      return true;
    }
    return false;
  }

  private isHardShiftPressed(): boolean {
    for (let i: number = 0; i < this.hardKeyCodes.length; i++) {
      if (HardKeyUtils.isShiftKey(this.hardKeyCodes[i])) {
        return true;
      }
    }
    return false;
  }

  private isHardRecognizedKey(keyCode: number): boolean {
    if (this.handleHardFunctionKeyCodeOnly(keyCode)) {
      return true;
    }
    return HardKeyUtils.getTextValue(keyCode, false).length > 0;
  }

  private handleHardFunctionKeyCodeOnly(keyCode: number): boolean {
    return keyCode === KeyCode.KEYCODE_DEL || keyCode === KeyCode.KEYCODE_ENTER ||
      keyCode === KeyCode.KEYCODE_SPACE || keyCode === KeyCode.KEYCODE_DPAD_LEFT ||
      keyCode === KeyCode.KEYCODE_DPAD_RIGHT || keyCode === KeyCode.KEYCODE_DPAD_UP ||
      keyCode === KeyCode.KEYCODE_DPAD_DOWN;
  }

  private syncCurrentSubtype(): void {
    try {
      let subtype: InputMethodSubtype = inputMethod.getCurrentInputMethodSubtype();
      this.applySubtype(subtype);
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'syncCurrentSubtype err: %{public}d %{public}s', err.code, err.message);
    }
  }

  private currentSubtypeId(): string {
    try {
      return inputMethod.getCurrentInputMethodSubtype().id;
    } catch (e) {
      let storageSubtypeId: string | undefined = AppStorage.get<string>('subtypeId');
      if (storageSubtypeId === SUBTYPE_STORAGE_ZH) {
        return SUBTYPE_ZH_ID;
      }
    }
    return SUBTYPE_EN_ID;
  }

  private applySubtype(subtype: InputMethodSubtype): void {
    pinyinEngine.clear();
    AppStorage.setOrCreate('ime.currentSubtypeId', subtype.id);
    if (subtype.id === SUBTYPE_EN_ID) {
      AppStorage.setOrCreate('subtypeId', SUBTYPE_STORAGE_EN);
    } else if (subtype.id === SUBTYPE_ZH_ID) {
      AppStorage.setOrCreate('subtypeId', SUBTYPE_STORAGE_ZH);
    }
  }

  private isSameInputMethod(left: inputMethod.InputMethodProperty,
                            right: inputMethod.InputMethodProperty): boolean {
    if (left.id === right.id) {
      return true;
    }
    return left.name === right.name;
  }

  private syncSecurityMode(): void {
    try {
      let securityMode: inputMethodEngine.SecurityMode = inputMethodAbility.getSecurityMode();
      this.applySecurityMode(securityMode);
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'syncSecurityMode err: %{public}d %{public}s', err.code, err.message);
      this.applySecurityMode(inputMethodEngine.SecurityMode.BASIC);
    }
  }

  private applySecurityMode(mode: inputMethodEngine.SecurityMode): void {
    AppStorage.setOrCreate(STORAGE_SECURITY_MODE, mode);
    AppStorage.setOrCreate(STORAGE_SECURITY_MODE_BASIC, mode === inputMethodEngine.SecurityMode.BASIC);
    hilog.info(0x0000, TAG, 'securityMode=%{public}d', mode);
  }

  private handleEditorAttributeChanged(attr: inputMethodEngine.EditorAttribute): void {
    AppStorage.setOrCreate('enterKeyType', attr.enterKeyType);
    AppStorage.setOrCreate('inputPattern', attr.inputPattern);
    this.inputHandler.updateEditorAttribute(attr);
    let immersiveMode: inputMethodEngine.ImmersiveMode = inputMethodEngine.ImmersiveMode.NONE_IMMERSIVE;
    if (attr.immersiveMode !== undefined) {
      immersiveMode = attr.immersiveMode;
    }
    this.setPanelImmersiveMode(this.resolvePanelImmersiveMode(immersiveMode));
  }

  private resolvePanelImmersiveMode(immersiveMode: inputMethodEngine.ImmersiveMode): inputMethodEngine.ImmersiveMode {
    if (immersiveMode === inputMethodEngine.ImmersiveMode.IMMERSIVE) {
      return this.preferredImmersiveMode();
    }
    if (immersiveMode === inputMethodEngine.ImmersiveMode.LIGHT_IMMERSIVE ||
      immersiveMode === inputMethodEngine.ImmersiveMode.DARK_IMMERSIVE) {
      return immersiveMode;
    }
    return inputMethodEngine.ImmersiveMode.NONE_IMMERSIVE;
  }

  private preferredImmersiveMode(): inputMethodEngine.ImmersiveMode {
    let skinPreset: number | undefined = AppStorage.get<number>('ime.skinPreset');
    if (skinPreset === undefined) {
      skinPreset = SettingsStore.getSettings().skinPreset;
    }
    if (skinPreset === KeyboardSkinPresetMode.NIGHT) {
      return inputMethodEngine.ImmersiveMode.DARK_IMMERSIVE;
    }
    return inputMethodEngine.ImmersiveMode.LIGHT_IMMERSIVE;
  }

  private currentPanelImmersiveMode(): inputMethodEngine.ImmersiveMode {
    let mode: number | undefined = AppStorage.get<number>(STORAGE_IMMERSIVE_MODE);
    if (mode === inputMethodEngine.ImmersiveMode.LIGHT_IMMERSIVE) {
      return inputMethodEngine.ImmersiveMode.LIGHT_IMMERSIVE;
    }
    if (mode === inputMethodEngine.ImmersiveMode.DARK_IMMERSIVE) {
      return inputMethodEngine.ImmersiveMode.DARK_IMMERSIVE;
    }
    return inputMethodEngine.ImmersiveMode.NONE_IMMERSIVE;
  }

  private setPanelImmersiveMode(mode: inputMethodEngine.ImmersiveMode): void {
    if (this.panel === undefined) {
      AppStorage.setOrCreate(STORAGE_IMMERSIVE_MODE, mode);
      return;
    }
    try {
      let currentMode: inputMethodEngine.ImmersiveMode = this.panel.getImmersiveMode();
      if (currentMode === mode) {
        AppStorage.setOrCreate(STORAGE_IMMERSIVE_MODE, mode);
        return;
      }
      this.panel.setImmersiveMode(mode);
      AppStorage.setOrCreate(STORAGE_IMMERSIVE_MODE, mode);
      hilog.info(0x0000, TAG, 'panel immersive mode=%{public}d', mode);
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'setPanelImmersiveMode err: %{public}d %{public}s', err.code, err.message);
    }
  }

  private unregisterListener(): void {
    try {
      inputMethodAbility.off('inputStart');
      inputMethodAbility.off('inputStop', this.inputStopCallback);
      inputMethodAbility.off('setSubtype');
      inputMethodAbility.off('securityModeChange', this.securityModeChangeCallback);
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, 'unregisterListener err: %{public}d %{public}s', err.code, err.message);
    }
    if (this.keyboardDelegate !== undefined) {
      this.keyboardDelegate.off('editorAttributeChanged', this.editorAttributeChangedCallback);
      this.keyboardDelegate.off('keyDown');
      this.keyboardDelegate.off('keyUp');
    }
  }
}

export const keyboardController: KeyboardController = new KeyboardController();
