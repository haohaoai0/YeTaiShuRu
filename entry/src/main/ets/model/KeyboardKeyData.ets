export class KeyData {
  title: string;
  content: string;
  upperContent: string;

  constructor(title: string, content: string, upperContent: string) {
    this.title = title;
    this.content = content;
    this.upperContent = upperContent;
  }
}

export class T9KeyData {
  digit: string;
  letters: string;
  hint: string;

  constructor(digit: string, letters: string, hint: string) {
    this.digit = digit;
    this.letters = letters;
    this.hint = hint;
  }
}

export enum KeyboardMode {
  LETTER = 0,
  NUMBER = 1,
  SYMBOL = 2,
  EDIT = 3,
  CLIPBOARD = 4,
  EMOJI = 5
}

export enum ShiftState {
  OFF = 0,    // 全部小写
  ONCE = 1,   // 仅下一个字母大写（按一次shift）
  LOCK = 2    // 大写锁定（双击shift）
}

// 标准 QWERTY 三行字母
export const LETTER_ROWS: KeyData[][] = [
  [
    new KeyData('1', 'q', 'Q'),
    new KeyData('2', 'w', 'W'),
    new KeyData('3', 'e', 'E'),
    new KeyData('4', 'r', 'R'),
    new KeyData('5', 't', 'T'),
    new KeyData('6', 'y', 'Y'),
    new KeyData('7', 'u', 'U'),
    new KeyData('8', 'i', 'I'),
    new KeyData('9', 'o', 'O'),
    new KeyData('0', 'p', 'P')
  ],
  [
    new KeyData('@', 'a', 'A'),
    new KeyData('#', 's', 'S'),
    new KeyData('$', 'd', 'D'),
    new KeyData('_', 'f', 'F'),
    new KeyData('&', 'g', 'G'),
    new KeyData('-', 'h', 'H'),
    new KeyData('+', 'j', 'J'),
    new KeyData('(', 'k', 'K'),
    new KeyData(')', 'l', 'L')
  ],
  [
    new KeyData('*', 'z', 'Z'),
    new KeyData('"', 'x', 'X'),
    new KeyData("'", 'c', 'C'),
    new KeyData(':', 'v', 'V'),
    new KeyData(';', 'b', 'B'),
    new KeyData('!', 'n', 'N'),
    new KeyData('?', 'm', 'M')
  ]
];

// 数字键盘第一行的右上标点（顶部小字）。供 Number 键盘行展示。
export const NUMBER_TITLE_ROW: string[] = ['1','2','3','4','5','6','7','8','9','0'];

export const T9_ROWS: T9KeyData[][] = [
  [
    new T9KeyData('1', '', '，。'),
    new T9KeyData('2', 'ABC', 'a b c'),
    new T9KeyData('3', 'DEF', 'd e f')
  ],
  [
    new T9KeyData('4', 'GHI', 'g h i'),
    new T9KeyData('5', 'JKL', 'j k l'),
    new T9KeyData('6', 'MNO', 'm n o')
  ],
  [
    new T9KeyData('7', 'PQRS', 'p q r s'),
    new T9KeyData('8', 'TUV', 't u v'),
    new T9KeyData('9', 'WXYZ', 'w x y z')
  ],
  [
    new T9KeyData('*', '', '符'),
    new T9KeyData('0', '', '空格'),
    new T9KeyData('#', '', '换行')
  ]
];

// 数字键盘 - 4 行
export const NUMBER_ROWS: string[][] = [
  ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
  ['@', '#', '$', '_', '&', '-', '+', '(', ')', '/'],
  ['*', '"', "'", ':', ';', '!', '?']
];

// 符号键盘
export const SYMBOL_ROWS: string[][] = [
  ['~', '`', '|', '•', '√', 'π', '÷', '×', '§', '∆'],
  ['£', '€', '¥', '¢', '^', '°', '=', '{', '}', '\\'],
  ['©', '®', '™', '%', '[', ']', '<']
];
