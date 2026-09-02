import { deviceInfo } from '@kit.BasicServicesKit';
import { uiMaterial } from '@kit.ArkUI';
import { SystemMaterialLevelMode } from '../model/ImeSettings';

const API_ARKUI_SYSTEM_MATERIAL_VERSION: number = 26;

class ArkUISystemMaterialState {
  supported: boolean = false;
  detected: boolean = false;
}

const arkUISystemMaterialState: ArkUISystemMaterialState = new ArkUISystemMaterialState();

function ensureArkUISystemMaterialDetected(): void {
  if (arkUISystemMaterialState.detected) {
    return;
  }
  arkUISystemMaterialState.detected = true;
  try {
    arkUISystemMaterialState.supported = deviceInfo.sdkApiVersion >= API_ARKUI_SYSTEM_MATERIAL_VERSION;
  } catch (e) {
    arkUISystemMaterialState.supported = false;
  }
}

export class LiquidMaterial {
  public static isAvailable(): boolean {
    ensureArkUISystemMaterialDetected();
    if (!arkUISystemMaterialState.supported) {
      return false;
    }
    let enabled: boolean | undefined = AppStorage.get<boolean>('ime.systemMaterialEnabled');
    if (enabled === undefined) {
      return true;
    }
    return enabled;
  }

  public static borderWidth(): number {
    return LiquidMaterial.isAvailable() ? 0 : 1;
  }

  public static borderColor(): ResourceColor {
    return LiquidMaterial.isAvailable() ? Color.Transparent : $r('app.color.material_border');
  }

  public static cardBackground(): ResourceColor {
    return LiquidMaterial.isAvailable() ? Color.Transparent : $r('app.color.material_card');
  }

  public static keyBackground(pressed: boolean): ResourceColor {
    if (LiquidMaterial.isAvailable()) {
      return Color.Transparent;
    }
    return pressed ? $r('app.color.material_key_pressed') : $r('app.color.material_key');
  }

  public static functionKeyBackground(active: boolean, pressed: boolean): ResourceColor {
    if (LiquidMaterial.isAvailable()) {
      return Color.Transparent;
    }
    if (active) {
      return $r('app.color.material_func_active');
    }
    if (pressed) {
      return $r('app.color.material_func_pressed');
    }
    return $r('app.color.material_func');
  }

  public static primaryBackground(pressed: boolean): ResourceColor {
    if (LiquidMaterial.isAvailable()) {
      return Color.Transparent;
    }
    return pressed ? $r('app.color.material_primary_pressed') : $r('app.color.material_primary');
  }

  public static chipBackground(selected: boolean): ResourceColor {
    if (LiquidMaterial.isAvailable()) {
      return Color.Transparent;
    }
    return selected ? $r('app.color.material_chip_selected') : $r('app.color.material_chip');
  }

  public static panel(): uiMaterial.Material | undefined {
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    return new uiMaterial.ImmersiveMaterial({
      style: LiquidMaterial.currentStyle(uiMaterial.ImmersiveStyle.THICK),
      materialColor: $r('app.color.material_panel'),
      applyShadow: false,
      interactive: false,
      lightEffect: null
    });
  }

  public static card(): uiMaterial.Material | undefined {
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    return new uiMaterial.ImmersiveMaterial({
      style: LiquidMaterial.currentStyle(uiMaterial.ImmersiveStyle.REGULAR),
      materialColor: $r('app.color.material_card'),
      applyShadow: true,
      interactive: true,
      lightEffect: { color: $r('app.color.material_light_effect') }
    });
  }

  public static key(pressed: boolean): uiMaterial.Material | undefined {
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    return new uiMaterial.ImmersiveMaterial({
      style: LiquidMaterial.currentStyle(pressed ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.REGULAR),
      materialColor: pressed ? $r('app.color.material_key_pressed') : $r('app.color.material_key'),
      applyShadow: true,
      interactive: true,
      lightEffect: { color: $r('app.color.material_light_effect') }
    });
  }

  public static functionKey(active: boolean, pressed: boolean): uiMaterial.Material | undefined {
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    let color: ResourceColor = $r('app.color.material_func');
    if (active) {
      color = $r('app.color.material_func_active');
    } else if (pressed) {
      color = $r('app.color.material_func_pressed');
    }
    return new uiMaterial.ImmersiveMaterial({
      style: LiquidMaterial.currentStyle(uiMaterial.ImmersiveStyle.REGULAR),
      materialColor: color,
      applyShadow: true,
      interactive: true,
      lightEffect: { color: $r('app.color.material_light_effect') }
    });
  }

  public static primary(pressed: boolean): uiMaterial.Material | undefined {
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    return new uiMaterial.ImmersiveMaterial({
      style: LiquidMaterial.currentStyle(uiMaterial.ImmersiveStyle.THICK),
      materialColor: pressed ? $r('app.color.material_primary_pressed') : $r('app.color.material_primary'),
      applyShadow: true,
      interactive: true,
      lightEffect: { color: $r('app.color.material_primary_light_effect') }
    });
  }

  public static chip(selected: boolean): uiMaterial.Material | undefined {
    if (!LiquidMaterial.isAvailable()) {
      return undefined;
    }
    return new uiMaterial.ImmersiveMaterial({
      style: LiquidMaterial.currentStyle(selected ? uiMaterial.ImmersiveStyle.THICK : uiMaterial.ImmersiveStyle.THIN),
      materialColor: selected ? $r('app.color.material_chip_selected') : $r('app.color.material_chip'),
      applyShadow: true,
      interactive: true,
      lightEffect: { color: $r('app.color.material_light_effect') }
    });
  }

  public static currentStyle(defaultStyle: uiMaterial.ImmersiveStyle): uiMaterial.ImmersiveStyle {
    let level: number | undefined = AppStorage.get<number>('ime.systemMaterialLevel');
    if (level === undefined) {
      return defaultStyle;
    }
    if (level === SystemMaterialLevelMode.ULTRA_THIN) {
      return uiMaterial.ImmersiveStyle.ULTRA_THIN;
    }
    if (level === SystemMaterialLevelMode.THIN) {
      return uiMaterial.ImmersiveStyle.THIN;
    }
    if (level === SystemMaterialLevelMode.REGULAR) {
      return uiMaterial.ImmersiveStyle.REGULAR;
    }
    if (level === SystemMaterialLevelMode.THICK) {
      return uiMaterial.ImmersiveStyle.THICK;
    }
    if (level === SystemMaterialLevelMode.ULTRA_THICK) {
      return uiMaterial.ImmersiveStyle.ULTRA_THICK;
    }
    return defaultStyle;
  }
}
