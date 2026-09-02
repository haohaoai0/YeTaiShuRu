import { deviceInfo } from '@kit.BasicServicesKit';
import {
  ScrollEffectOptions,
  ScrollEffectType,
  SystemMaterialParams,
  TitleBarStyleOptions
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { SystemMaterialLevelMode } from '../model/ImeSettings';

const API_HDS_MATERIAL_VERSION: number = 60100;
const API_HDS_MATERIAL_VERSION_RAW: number = 23;

class HdsMaterialDetectionState {
  isHighVersion: boolean = false;
  supportsImmersive: boolean = false;
  detected: boolean = false;
}

class HdsScrollEffectConfig implements ScrollEffectOptions {
  enableScrollEffect: boolean = true;
  scrollEffectType: ScrollEffectType = ScrollEffectType.GRADIENT_BLUR;
}

class HdsSystemMaterialEffectConfig implements SystemMaterialParams {
  materialType: hdsMaterial.MaterialType = hdsMaterial.MaterialType.IMMERSIVE;
  materialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.ADAPTIVE;
}

export class HdsTitleBarStyleConfig implements TitleBarStyleOptions {
  scrollEffectOpts: ScrollEffectOptions = new HdsScrollEffectConfig();
  systemMaterialEffect: SystemMaterialParams = new HdsSystemMaterialEffectConfig();
  thermoCtrl: boolean = true;
}

const detectionState: HdsMaterialDetectionState = new HdsMaterialDetectionState();

function isHighVersion(version: number): boolean {
  if (version < 1000) {
    return version >= API_HDS_MATERIAL_VERSION_RAW;
  }
  return version >= API_HDS_MATERIAL_VERSION;
}

function ensureDetected(): void {
  if (detectionState.detected) {
    return;
  }
  detectionState.detected = true;
  try {
    detectionState.isHighVersion = isHighVersion(deviceInfo.distributionOSApiVersion);
  } catch (e) {
    detectionState.isHighVersion = false;
  }
  if (!detectionState.isHighVersion) {
    detectionState.supportsImmersive = false;
    return;
  }
  try {
    let types: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
    for (let i: number = 0; i < types.length; i++) {
      if (types[i] === hdsMaterial.MaterialType.IMMERSIVE) {
        detectionState.supportsImmersive = true;
        return;
      }
    }
  } catch (e) {
    detectionState.supportsImmersive = false;
  }
}

export class HdsMaterialStyle {
  public static isAvailable(): boolean {
    ensureDetected();
    return detectionState.isHighVersion;
  }

  public static isImmersiveSupported(): boolean {
    ensureDetected();
    return detectionState.supportsImmersive;
  }

  public static titleBarStyle(enabled: boolean, level: number): HdsTitleBarStyleConfig | undefined {
    ensureDetected();
    if (!enabled || !detectionState.isHighVersion) {
      return undefined;
    }
    let style: HdsTitleBarStyleConfig = new HdsTitleBarStyleConfig();
    let materialEffect: HdsSystemMaterialEffectConfig = new HdsSystemMaterialEffectConfig();
    materialEffect.materialType = detectionState.supportsImmersive ?
      hdsMaterial.MaterialType.IMMERSIVE :
      hdsMaterial.MaterialType.ADAPTIVE;
    materialEffect.materialLevel = HdsMaterialStyle.toMaterialLevel(level);
    style.systemMaterialEffect = materialEffect;
    return style;
  }

  public static toMaterialLevel(level: number): hdsMaterial.MaterialLevel {
    if (level === SystemMaterialLevelMode.THICK || level === SystemMaterialLevelMode.ULTRA_THICK) {
      return hdsMaterial.MaterialLevel.EXQUISITE;
    }
    if (level === SystemMaterialLevelMode.REGULAR) {
      return hdsMaterial.MaterialLevel.GENTLE;
    }
    if (level === SystemMaterialLevelMode.ULTRA_THIN || level === SystemMaterialLevelMode.THIN) {
      return hdsMaterial.MaterialLevel.SMOOTH;
    }
    return hdsMaterial.MaterialLevel.ADAPTIVE;
  }
}
