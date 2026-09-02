import { KeyCode } from '@kit.InputKit';

export class HardKeyUtils {
  public static isShiftKey(keyCode: number): boolean {
    return keyCode === KeyCode.KEYCODE_SHIFT_LEFT || keyCode === KeyCode.KEYCODE_SHIFT_RIGHT;
  }

  public static isAltKey(keyCode: number): boolean {
    return keyCode === KeyCode.KEYCODE_ALT_LEFT || keyCode === KeyCode.KEYCODE_ALT_RIGHT;
  }

  public static isLetterKey(keyCode: number): boolean {
    return keyCode >= KeyCode.KEYCODE_A && keyCode <= KeyCode.KEYCODE_Z;
  }

  public static isDigitText(value: string): boolean {
    if (value.length !== 1) {
      return false;
    }
    let code: number = value.charCodeAt(0);
    return code >= '0'.charCodeAt(0) && code <= '9'.charCodeAt(0);
  }

  public static getTextValue(keyCode: number, shiftPressed: boolean): string {
    if (keyCode >= KeyCode.KEYCODE_A && keyCode <= KeyCode.KEYCODE_Z) {
      let offset: number = keyCode - KeyCode.KEYCODE_A;
      let code: number = 'a'.charCodeAt(0) + offset;
      let value: string = String.fromCharCode(code);
      if (shiftPressed) {
        return value.toUpperCase();
      }
      return value;
    }
    if (keyCode >= KeyCode.KEYCODE_0 && keyCode <= KeyCode.KEYCODE_9) {
      return (keyCode - KeyCode.KEYCODE_0).toString();
    }
    if (keyCode === KeyCode.KEYCODE_COMMA) {
      return ',';
    }
    if (keyCode === KeyCode.KEYCODE_PERIOD) {
      return '.';
    }
    if (keyCode === KeyCode.KEYCODE_SEMICOLON) {
      return ';';
    }
    if (keyCode === KeyCode.KEYCODE_SLASH) {
      return '/';
    }
    if (keyCode === KeyCode.KEYCODE_EQUALS) {
      return '=';
    }
    return '';
  }
}
