import { uiMaterial } from '@kit.ArkUI';
import { LiquidMaterial } from './LiquidMaterial';
import { KeyboardSkinBackgroundMode, KeyboardSkinPresetMode } from '../model/ImeSettings';

export class KeyboardSkinStyle {
  private static mintMaterialColor: string = '#FFE8F7F4';
  private static mintLightColor: string = '#FF0D9D68';
  private static nightMaterialColor: string = '#55FFFFFF';
  private static nightLightColor: string = '#FF4F9CFF';
  private static sunsetMaterialColor: string = '#FFFFFAF2';
  private static sunsetLightColor: string = '#FFFF6B35';
  private static customLightColor: string = '#FF007DFF';

  private static rainbowColors: string[] = [
    '#FFFF6B6B', // 红
    '#FFFF8E53', // 橙
    '#FFFFCD56', // 黄
    '#FF4BC0C8', // 青
    '#FF36A2EB', // 蓝
    '#FF9966FF', // 紫
    '#FFCC66FF', // 粉
    '#FF66CCCC', // 青绿
    '#FF66CC99', // 绿
    '#FFFF99CC'  // 粉红
  ];

  public static rainbowKeyColor(index: number): ResourceColor {
    let colorIndex = index % KeyboardSkinStyle.rainbowColors.length;
    return KeyboardSkinStyle.rainbowColors[colorIndex];
  }

  public static rainbowKeyColorPressed(index: number): ResourceColor {
    let colorIndex = index % KeyboardSkinStyle.rainbowColors.length;
    let baseColor = KeyboardSkinStyle.rainbowColors[colorIndex];
    return KeyboardSkinStyle.darkenColor(baseColor, 0.15);
  }

  private static rainbowColor(index: number): string {
    let colorIndex: number = index % KeyboardSkinStyle.rainbowColors.length;
    return KeyboardSkinStyle.rainbowColors[colorIndex];
  }

  private static rainbowColorPressed(index: number): string {
    return KeyboardSkinStyle.darkenColor(KeyboardSkinStyle.rainbowColor(index), 0.15);
  }

  private static usesRainbowKeyColor(preset: number, keyIndex: number): boolean {
    return preset === KeyboardSkinPresetMode.RAINBOW && keyIndex >= 0;
  }

  private static usesRainbowTextColor(preset: number, keyIndex: number): boolean {
    return preset === KeyboardSkinPresetMode.RAINBOW_TEXT && keyIndex >= 0;
  }

  private static colorWithAlpha(color: string, alpha: string): string {
    if (color.length < 9) {
      return color;
    }
    return '#' + alpha + color.substring(3, 9);
  }

  private static toHex2(n: number): string {
    let h: string = n.toString(16);
    if (h.length < 2) {
      return '0' + h;
    }
    return h;
  }

  private static darkenColor(color: string, factor: number): string {
    if (color.length < 9) {
      return color;
    }
    let a: string = color.substring(1, 3);
    let r: number = parseInt(color.substring(3, 5), 16);
    let g: number = parseInt(color.substring(5, 7), 16);
    let b: number = parseInt(color.substring(7, 9), 16);
    r = Math.max(0, Math.floor(r * (1 - factor)));
    g = Math.max(0, Math.floor(g * (1 - factor)));
    b = Math.max(0, Math.floor(b * (1 - factor)));
    return '#' + a + KeyboardSkinStyle.toHex2(r) + KeyboardSkinStyle.toHex2(g) + KeyboardSkinStyle.toHex2(b);
  }

  private static colorToResource(color: string): ResourceColor {
    return color;
  }

  public static isDefaultSkin(preset: number): boolean {
    return preset === KeyboardSkinPresetMode.LIQUID;
  }

  public static usesImageBackground(backgroundMode: number, imageUri: string): boolean {
    return backgroundMode === KeyboardSkinBackgroundMode.IMAGE;
  }

  public static panelBackground(preset: number, backgroundMode: number, customColor: string): ResourceColor {
    return $r('app.color.kb_background');
  }

  public static cardBackground(preset: number): ResourceColor {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.cardBackground();
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      return KeyboardSkinStyle.mintMaterialColor;
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      return '#332A3447';
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      return KeyboardSkinStyle.sunsetMaterialColor;
    }
    return '#E6FFFFFF';
  }

  public static keyBackground(preset: number, customKeyColor: string, pressed: boolean,
    keyIndex: number = -1): ResourceColor {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.keyBackground(pressed);
    }
    if (KeyboardSkinStyle.usesRainbowKeyColor(preset, keyIndex)) {
      return pressed ? KeyboardSkinStyle.rainbowColorPressed(keyIndex) : KeyboardSkinStyle.rainbowColor(keyIndex);
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      return pressed ? '#FFFFFFFF' : KeyboardSkinStyle.mintMaterialColor;
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      return pressed ? '#88FFFFFF' : '#55FFFFFF';
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      return pressed ? '#FFFFFFFF' : '#FFFFFAF2';
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW) {
      return pressed ? '#FFFFFFFF' : '#E6FFFFFF';
    }
    return pressed ? '#FFFFFFFF' : customKeyColor;
  }

  public static functionKeyBackground(preset: number, customKeyColor: string, active: boolean,
    pressed: boolean, keyIndex: number = -1): ResourceColor {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.functionKeyBackground(active, pressed);
    }
    if (KeyboardSkinStyle.usesRainbowKeyColor(preset, keyIndex)) {
      return (active || pressed) ? KeyboardSkinStyle.rainbowColorPressed(keyIndex) :
        KeyboardSkinStyle.rainbowColor(keyIndex);
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      if (active) {
        return '#FF8EE6C1';
      }
      return pressed ? '#FFC4EADC' : '#FFD7F2E8';
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      if (active) {
        return '#AA4F9CFF';
      }
      return pressed ? '#AA3C465A' : '#772A3447';
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      if (active) {
        return '#FFFFA55E';
      }
      return pressed ? '#FFFFCBB0' : '#FFFFDDC6';
    }
    if (active) {
      return '#FFBBD8FF';
    }
    return pressed ? '#FFFFFFFF' : customKeyColor;
  }

  public static primaryBackground(preset: number, pressed: boolean, keyIndex: number = -1): ResourceColor {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.primaryBackground(pressed);
    }
    if (KeyboardSkinStyle.usesRainbowKeyColor(preset, keyIndex)) {
      return pressed ? KeyboardSkinStyle.rainbowColorPressed(keyIndex) : KeyboardSkinStyle.rainbowColor(keyIndex);
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      return pressed ? '#FF08784F' : '#FF0D9D68';
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      return pressed ? '#FF1D67D6' : '#FF4F9CFF';
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      return pressed ? '#FFD94F1F' : '#FFFF6B35';
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW) {
      return pressed ? '#FFCC66FF' : '#FF9966FF';
    }
    return pressed ? '#FF1D67D6' : '#FF007DFF';
  }

  public static chipBackground(preset: number, selected: boolean): ResourceColor {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.chipBackground(selected);
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      return selected ? '#994F9CFF' : '#552A3447';
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      return selected ? '#FF8EE6C1' : '#E6FFFFFF';
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      return selected ? '#FFFFA55E' : '#FFFFFAF2';
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW) {
      return selected ? '#FF9966FF' : '#E6FFFFFF';
    }
    return selected ? '#FFBBD8FF' : '#E6FFFFFF';
  }

  public static keyTextColor(preset: number): ResourceColor {
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      return '#FFFFFFFF';
    }
    return $r('app.color.key_text');
  }

  public static mutedTextColor(preset: number): ResourceColor {
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      return '#B3FFFFFF';
    }
    return $r('app.color.text_muted');
  }

  public static keyMainTextColor(preset: number, keyIndex: number = -1): ResourceColor {
    if (KeyboardSkinStyle.usesRainbowTextColor(preset, keyIndex)) {
      return KeyboardSkinStyle.rainbowColor(keyIndex);
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW) {
      return '#FFFFFFFF';
    }
    return KeyboardSkinStyle.keyTextColor(preset);
  }

  public static keyHintTextColor(preset: number, keyIndex: number = -1): ResourceColor {
    if (KeyboardSkinStyle.usesRainbowTextColor(preset, keyIndex)) {
      return KeyboardSkinStyle.colorWithAlpha(KeyboardSkinStyle.rainbowColor(keyIndex), 'AA');
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW) {
      return '#66FFFFFF';
    }
    return KeyboardSkinStyle.mutedTextColor(preset);
  }

  public static primaryTextColor(preset: number, keyIndex: number = -1): ResourceColor {
    if (KeyboardSkinStyle.usesRainbowTextColor(preset, keyIndex)) {
      return KeyboardSkinStyle.rainbowColor(keyIndex);
    }
    return '#FFFFFFFF';
  }

  public static usesKeyColorOverlay(preset: number): boolean {
    return !KeyboardSkinStyle.isDefaultSkin(preset);
  }

  public static keyColorOverlayOpacity(pressed: boolean): number {
    return pressed ? 0.92 : 0.82;
  }

  public static borderWidth(preset: number): number {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.borderWidth();
    }
    return 1;
  }

  public static borderColor(preset: number): ResourceColor {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.borderColor();
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      return '#24FFFFFF';
    }
    return '#22182235';
  }

  public static panelMaterial(preset: number): uiMaterial.Material | undefined {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.panel();
    }
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.mintMaterialColor),
        applyShadow: false,
        interactive: false,
        lightEffect: null
      });
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.nightMaterialColor),
        applyShadow: false,
        interactive: false,
        lightEffect: null
      });
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.sunsetMaterialColor),
        applyShadow: false,
        interactive: false,
        lightEffect: null
      });
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW) {
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource('#DDF8F9FA'),
        applyShadow: false,
        interactive: false,
        lightEffect: null
      });
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW_TEXT) {
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource('#DDF8F9FA'),
        applyShadow: false,
        interactive: false,
        lightEffect: null
      });
    }
    return undefined;
  }

  public static cardMaterial(preset: number): uiMaterial.Material | undefined {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.card();
    }
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.nightMaterialColor),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.nightLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.mintMaterialColor),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.mintLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.sunsetMaterialColor),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.sunsetLightColor) }
      });
    }
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.REGULAR,
      materialColor: KeyboardSkinStyle.colorToResource('#E6FFFFFF'),
      applyShadow: true,
      interactive: true,
      lightEffect: { color: KeyboardSkinStyle.colorToResource('#CCFFFFFF') }
    });
  }

  public static keyMaterial(preset: number, pressed: boolean,
    keyIndex: number = 0, customKeyColor: string = '#E6FFFFFF'): uiMaterial.Material | undefined {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.key(pressed);
    }
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      let color: string = pressed ? '#FFFFFFFF' : KeyboardSkinStyle.mintMaterialColor;
      return new uiMaterial.ImmersiveMaterial({
        style: pressed ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.mintLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      let color: string = pressed ? '#88FFFFFF' : KeyboardSkinStyle.nightMaterialColor;
      return new uiMaterial.ImmersiveMaterial({
        style: pressed ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.nightLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      let color: string = pressed ? '#FFFFFFFF' : KeyboardSkinStyle.sunsetMaterialColor;
      return new uiMaterial.ImmersiveMaterial({
        style: pressed ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.sunsetLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW) {
      let keyColor: string = pressed ? KeyboardSkinStyle.rainbowColorPressed(keyIndex) :
        KeyboardSkinStyle.rainbowColor(keyIndex);
      let lightColor: string = KeyboardSkinStyle.rainbowColor(keyIndex);
      return new uiMaterial.ImmersiveMaterial({
        style: pressed ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(keyColor),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(lightColor) }
      });
    }
    return new uiMaterial.ImmersiveMaterial({
      style: pressed ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.REGULAR,
      materialColor: KeyboardSkinStyle.colorToResource(pressed ? '#FFFFFFFF' : customKeyColor),
      applyShadow: true,
      interactive: true,
      lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.customLightColor) }
    });
  }

  public static functionKeyMaterial(preset: number, active: boolean,
    pressed: boolean, keyIndex: number = -1, customKeyColor: string = '#E6FFFFFF'): uiMaterial.Material | undefined {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.functionKey(active, pressed);
    }
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    if (KeyboardSkinStyle.usesRainbowKeyColor(preset, keyIndex)) {
      let color: string = (active || pressed) ? KeyboardSkinStyle.rainbowColorPressed(keyIndex) :
        KeyboardSkinStyle.rainbowColor(keyIndex);
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.rainbowColor(keyIndex)) }
      });
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      let color: string = active ? '#FF8EE6C1' : (pressed ? '#FFC4EADC' : '#FFD7F2E8');
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.mintLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      let color: string = active ? '#AA4F9CFF' : (pressed ? '#AA3C465A' : '#772A3447');
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.nightLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      let color: string = active ? '#FFFFA55E' : (pressed ? '#FFFFCBB0' : '#FFFFDDC6');
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.sunsetLightColor) }
      });
    }
    let color: string = active ? '#FFBBD8FF' : (pressed ? '#FFFFFFFF' : customKeyColor);
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.REGULAR,
      materialColor: KeyboardSkinStyle.colorToResource(color),
      applyShadow: true,
      interactive: true,
      lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.customLightColor) }
    });
  }

  public static primaryMaterial(preset: number, pressed: boolean,
    keyIndex: number = -1): uiMaterial.Material | undefined {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.primary(pressed);
    }
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    if (KeyboardSkinStyle.usesRainbowKeyColor(preset, keyIndex)) {
      let color: string = pressed ? KeyboardSkinStyle.rainbowColorPressed(keyIndex) :
        KeyboardSkinStyle.rainbowColor(keyIndex);
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.rainbowColor(keyIndex)) }
      });
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      let color: string = pressed ? '#FF08784F' : '#FF0D9D68';
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.mintLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      let color: string = pressed ? '#FF1D67D6' : '#FF4F9CFF';
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.nightLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      let color: string = pressed ? '#FFD94F1F' : '#FFFF6B35';
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.sunsetLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW) {
      let color: string = pressed ? '#FFCC66FF' : '#FF9966FF';
      return new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THICK,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource('#FF9966FF') }
      });
    }
    let color: string = pressed ? '#FF1D67D6' : '#FF007DFF';
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THICK,
      materialColor: KeyboardSkinStyle.colorToResource(color),
      applyShadow: true,
      interactive: true,
      lightEffect: { color: KeyboardSkinStyle.colorToResource('#FFFFFFFF') }
    });
  }

  public static chipMaterial(preset: number, selected: boolean): uiMaterial.Material | undefined {
    if (KeyboardSkinStyle.isDefaultSkin(preset)) {
      return LiquidMaterial.chip(selected);
    }
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    if (preset === KeyboardSkinPresetMode.MINT) {
      let color: string = selected ? '#FF8EE6C1' : '#E6FFFFFF';
      return new uiMaterial.ImmersiveMaterial({
        style: selected ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.THIN,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.mintLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.NIGHT) {
      let color: string = selected ? '#994F9CFF' : '#552A3447';
      return new uiMaterial.ImmersiveMaterial({
        style: selected ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.THIN,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.nightLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.SUNSET) {
      let color: string = selected ? '#FFFFA55E' : '#FFFFFAF2';
      return new uiMaterial.ImmersiveMaterial({
        style: selected ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.THIN,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource(KeyboardSkinStyle.sunsetLightColor) }
      });
    }
    if (preset === KeyboardSkinPresetMode.RAINBOW) {
      let color: string = selected ? '#FF9966FF' : '#E6FFFFFF';
      return new uiMaterial.ImmersiveMaterial({
        style: selected ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.THIN,
        materialColor: KeyboardSkinStyle.colorToResource(color),
        applyShadow: true,
        interactive: true,
        lightEffect: { color: KeyboardSkinStyle.colorToResource('#FF9966FF') }
      });
    }
    let color: string = selected ? '#FFBBD8FF' : '#E6FFFFFF';
    return new uiMaterial.ImmersiveMaterial({
      style: selected ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.THIN,
      materialColor: KeyboardSkinStyle.colorToResource(color),
      applyShadow: true,
      interactive: true,
      lightEffect: { color: KeyboardSkinStyle.colorToResource('#CC007DFF') }
    });
  }
}
