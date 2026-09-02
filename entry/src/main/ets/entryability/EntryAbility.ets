import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { InputMethodStatus } from '../model/InputMethodStatus';
import { SettingsStore } from '../model/ImeSettings';
import { SETTINGS_LAUNCH_PARAM_ROUTE, SETTINGS_LAUNCH_ROUTE_KEY } from '../model/SettingsLaunch';

const TAG: string = 'EntryAbility';
const SETTINGS_HOME_PAGE: string = 'pages/Index';
const INPUT_METHOD_REQUIRED_PAGE: string = 'pages/InputMethodRequired';

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | undefined = undefined;
  private currentContentPath: string = '';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'onCreate');
    this.publishLaunchRoute(want);
    SettingsStore.init(this.context);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'onNewWant');
    this.publishLaunchRoute(want);
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, TAG, 'onWindowStageCreate');
    this.windowStage = windowStage;
    this.loadEntryContent(windowStage);
  }

  private loadEntryContent(windowStage: window.WindowStage): void {
    let contentPath: string = InputMethodStatus.isLiquidImeCurrent() ? SETTINGS_HOME_PAGE : INPUT_METHOD_REQUIRED_PAGE;
    if (this.currentContentPath === contentPath) {
      return;
    }
    windowStage.loadContent(contentPath, (err) => {
      if (err.code) {
        hilog.error(0x0000, TAG, 'Failed to load content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      this.currentContentPath = contentPath;
      hilog.info(0x0000, TAG, 'Succeeded in loading the content.');
      this.setupFullScreenAvoidArea(windowStage);
    });
  }

  private setupFullScreenAvoidArea(windowStage: window.WindowStage): void {
    try {
      let windowClass: window.Window = windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true).then(() => {
        this.publishAvoidArea(windowClass);
        windowClass.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
          if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
            AppStorage.setOrCreate('topRectHeight', data.area.topRect.height);
          } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
            AppStorage.setOrCreate('bottomRectHeight', data.area.bottomRect.height);
          }
        });
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, TAG, 'Failed to enable fullscreen. Cause: %{public}s', JSON.stringify(err));
      });
    } catch (e) {
      hilog.error(0x0000, TAG, 'Failed to setup avoid area. Cause: %{public}s', JSON.stringify(e));
      AppStorage.setOrCreate('topRectHeight', 0);
      AppStorage.setOrCreate('bottomRectHeight', 0);
    }
  }

  private publishAvoidArea(windowClass: window.Window): void {
    let topAvoidArea: window.AvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    let bottomAvoidArea: window.AvoidArea =
      windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    AppStorage.setOrCreate('topRectHeight', topAvoidArea.topRect.height);
    AppStorage.setOrCreate('bottomRectHeight', bottomAvoidArea.bottomRect.height);
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, TAG, 'onWindowStageDestroy');
    this.windowStage = undefined;
    this.currentContentPath = '';
  }

  onForeground(): void {
    hilog.info(0x0000, TAG, 'onForeground');
    if (this.windowStage !== undefined) {
      this.loadEntryContent(this.windowStage);
    }
  }

  onBackground(): void {
    hilog.info(0x0000, TAG, 'onBackground');
  }

  private publishLaunchRoute(want: Want): void {
    let route: string = this.readLaunchRoute(want);
    AppStorage.setOrCreate(SETTINGS_LAUNCH_ROUTE_KEY, route);
  }

  private readLaunchRoute(want: Want): string {
    if (want.parameters === undefined) {
      return '';
    }
    let parameters: Record<string, Object> = want.parameters;
    let routeValue: Object | undefined = parameters[SETTINGS_LAUNCH_PARAM_ROUTE];
    if (routeValue === undefined) {
      return '';
    }
    return routeValue.toString();
  }
}
