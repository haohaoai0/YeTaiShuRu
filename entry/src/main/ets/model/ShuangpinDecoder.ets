class ShuangpinCodeMap {
  key: string = '';
  value: string = '';

  constructor(key: string, value: string) {
    this.key = key;
    this.value = value;
  }
}

const XIAOHE_INITIALS: Array<ShuangpinCodeMap> = [
  new ShuangpinCodeMap('b', 'b'),
  new ShuangpinCodeMap('p', 'p'),
  new ShuangpinCodeMap('m', 'm'),
  new ShuangpinCodeMap('f', 'f'),
  new ShuangpinCodeMap('d', 'd'),
  new ShuangpinCodeMap('t', 't'),
  new ShuangpinCodeMap('n', 'n'),
  new ShuangpinCodeMap('l', 'l'),
  new ShuangpinCodeMap('g', 'g'),
  new ShuangpinCodeMap('k', 'k'),
  new ShuangpinCodeMap('h', 'h'),
  new ShuangpinCodeMap('j', 'j'),
  new ShuangpinCodeMap('q', 'q'),
  new ShuangpinCodeMap('x', 'x'),
  new ShuangpinCodeMap('r', 'r'),
  new ShuangpinCodeMap('z', 'z'),
  new ShuangpinCodeMap('c', 'c'),
  new ShuangpinCodeMap('s', 's'),
  new ShuangpinCodeMap('y', 'y'),
  new ShuangpinCodeMap('w', 'w'),
  new ShuangpinCodeMap('v', 'zh'),
  new ShuangpinCodeMap('i', 'ch'),
  new ShuangpinCodeMap('u', 'sh')
];

const XIAOHE_FINALS: Array<ShuangpinCodeMap> = [
  new ShuangpinCodeMap('a', 'a'),
  new ShuangpinCodeMap('o', 'uo'),
  new ShuangpinCodeMap('e', 'e'),
  new ShuangpinCodeMap('i', 'i'),
  new ShuangpinCodeMap('u', 'u'),
  new ShuangpinCodeMap('d', 'ai'),
  new ShuangpinCodeMap('w', 'ei'),
  new ShuangpinCodeMap('c', 'ao'),
  new ShuangpinCodeMap('z', 'ou'),
  new ShuangpinCodeMap('q', 'iu'),
  new ShuangpinCodeMap('p', 'ie'),
  new ShuangpinCodeMap('t', 've'),
  new ShuangpinCodeMap('j', 'an'),
  new ShuangpinCodeMap('f', 'en'),
  new ShuangpinCodeMap('b', 'in'),
  new ShuangpinCodeMap('y', 'un'),
  new ShuangpinCodeMap('h', 'ang'),
  new ShuangpinCodeMap('g', 'eng'),
  new ShuangpinCodeMap('r', 'uan'),
  new ShuangpinCodeMap('n', 'iao'),
  new ShuangpinCodeMap('m', 'ian')
];

export class ShuangpinDecoder {
  public static decode(code: string): string {
    let value: string = code.toLowerCase();
    let result: string = '';
    let index: number = 0;
    while (index + 1 < value.length) {
      result = result + ShuangpinDecoder.decodePair(value.charAt(index), value.charAt(index + 1));
      index = index + 2;
    }
    if (index < value.length) {
      result = result + ShuangpinDecoder.decodePartial(value.charAt(index));
    }
    return result;
  }

  private static decodePair(firstKey: string, secondKey: string): string {
    if (ShuangpinDecoder.isZeroInitialKey(firstKey)) {
      return ShuangpinDecoder.decodeZeroInitial(firstKey, secondKey);
    }
    let initial: string = ShuangpinDecoder.lookup(XIAOHE_INITIALS, firstKey);
    if (initial.length === 0) {
      initial = firstKey;
    }
    let finalPart: string = ShuangpinDecoder.lookupFinalByContext(initial, secondKey);
    if (finalPart.length === 0) {
      return initial + secondKey;
    }
    return ShuangpinDecoder.joinSyllable(initial, finalPart);
  }

  private static decodePartial(key: string): string {
    let initial: string = ShuangpinDecoder.lookup(XIAOHE_INITIALS, key);
    if (initial.length > 0) {
      return initial;
    }
    return key;
  }

  private static decodeZeroInitial(firstKey: string, secondKey: string): string {
    if (firstKey === 'a') {
      if (secondKey === 'a') {
        return 'a';
      }
      if (secondKey === 'i' || secondKey === 'd') {
        return 'ai';
      }
      if (secondKey === 'n' || secondKey === 'j') {
        return 'an';
      }
      if (secondKey === 'g' || secondKey === 'h') {
        return 'ang';
      }
      if (secondKey === 'o' || secondKey === 'c') {
        return 'ao';
      }
    }
    if (firstKey === 'e') {
      if (secondKey === 'e') {
        return 'e';
      }
      if (secondKey === 'i' || secondKey === 'w') {
        return 'ei';
      }
      if (secondKey === 'n' || secondKey === 'f') {
        return 'en';
      }
      if (secondKey === 'g' || secondKey === 'h') {
        return 'eng';
      }
      if (secondKey === 'r') {
        return 'er';
      }
    }
    if (firstKey === 'o') {
      if (secondKey === 'o') {
        return 'o';
      }
      if (secondKey === 'u' || secondKey === 'z') {
        return 'ou';
      }
    }
    let finalPart: string = ShuangpinDecoder.lookupFinalByContext('', secondKey);
    if (finalPart.length === 0) {
      return firstKey + secondKey;
    }
    return firstKey + finalPart;
  }

  private static lookupFinalByContext(initial: string, key: string): string {
    if (key === 'v') {
      if (initial === 'j' || initial === 'q' || initial === 'x' || initial === 'y') {
        return 'u';
      }
      if (initial === 'n' || initial === 'l') {
        return 'v';
      }
      return 'ui';
    }
    if (key === 'k') {
      if (initial === 'g' || initial === 'k' || initial === 'h' || initial === 'w') {
        return 'uai';
      }
      return 'ing';
    }
    if (key === 'l') {
      if (initial === 'g' || initial === 'k' || initial === 'h' || initial === 'w' ||
        initial === 'zh' || initial === 'ch' || initial === 'sh') {
        return 'uang';
      }
      return 'iang';
    }
    if (key === 'x') {
      if (initial === 'g' || initial === 'k' || initial === 'h' || initial === 'w' ||
        initial === 'zh' || initial === 'ch' || initial === 'sh') {
        return 'ua';
      }
      return 'ia';
    }
    if (key === 's') {
      if (initial === 'j' || initial === 'q' || initial === 'x' || initial === 'y') {
        return 'iong';
      }
      return 'ong';
    }
    return ShuangpinDecoder.lookup(XIAOHE_FINALS, key);
  }

  private static joinSyllable(initial: string, finalPart: string): string {
    if (initial === 'w') {
      if (finalPart === 'u') {
        return 'wu';
      }
      if (finalPart === 'uo') {
        return 'wo';
      }
      return initial + finalPart;
    }
    if (initial === 'y') {
      if (finalPart === 'i') {
        return 'yi';
      }
      if (finalPart === 'u' || finalPart === 'v') {
        return 'yu';
      }
      if (finalPart === 've') {
        return 'yue';
      }
      if (finalPart === 'un') {
        return 'yun';
      }
      if (finalPart === 'uan') {
        return 'yuan';
      }
      return initial + finalPart;
    }
    if (finalPart === 've') {
      if (initial === 'n' || initial === 'l') {
        return initial + 've';
      }
      return initial + 'ue';
    }
    return initial + finalPart;
  }

  private static isZeroInitialKey(key: string): boolean {
    return key === 'a' || key === 'e' || key === 'o';
  }

  private static lookup(mappings: Array<ShuangpinCodeMap>, key: string): string {
    for (let i: number = 0; i < mappings.length; i++) {
      let item: ShuangpinCodeMap = mappings[i];
      if (item.key === key) {
        return item.value;
      }
    }
    return '';
  }
}
