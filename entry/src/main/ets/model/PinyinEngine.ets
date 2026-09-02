import { util } from '@kit.ArkTS';
import { i18n, resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { KeyboardLayoutMode, SettingsStore } from './ImeSettings';
import { ShuangpinDecoder } from './ShuangpinDecoder';

const TAG: string = 'PinyinEngine';
const RAW_DICT_PATHS: Array<string> = [
  'pinyin_dict.txt',
  'dict_clean_sc.txt',
  'dict_unihan_sc.txt'
];
const MAX_CANDIDATE_COUNT: number = 9;
const MAX_CANDIDATE_POOL: number = 24;
const MAX_COMPOSING_LENGTH: number = 64;
const SEGMENT_CHAR_BONUS: number = 120;
const SEGMENT_WORD_BONUS: number = 180;
const SEGMENT_SENTENCE_BONUS: number = 500;
const NAME_CANDIDATE_BONUS: number = 120000;
const NAME_SYNTHETIC_SCORE: number = 60000;
const GIVEN_NAME_CHAR_BONUS: number = 4000;
const GIVEN_NAME_BASE_SCORE_LIMIT: number = 5000;
const COMMON_GIVEN_NAME_CHARS: string =
  '伟刚勇毅俊峰强军平保东文辉力明永健世广志义兴良海山仁波宁贵福生龙元全国胜学祥才发武新利清飞彬富顺信子杰涛昌成康星光天达安岩中茂进林有坚和彪博诚先敬震振壮会思群豪心邦承乐绍功松善厚庆磊民友裕河哲江超浩亮政谦亨奇固之轮翰朗伯宏言若鸣朋斌梁栋维启克伦翔旭鹏泽晨辰士以建家致树炎德行时泰盛雄琛钧冠策腾楠榕风航弘华敏静丽芳娜娟艳婷慧莹晶佳雪洁欣琪琳三云宇轩涵梓睿昊然洋';

export enum CandidateSource {
  DICTIONARY = 0,
  RAW_CODE = 1,
  SEGMENTED = 2,
  NAME = 3
}

export class PinyinDictionaryEntry {
  pinyin: string = '';
  lookupPinyin: string = '';
  fuzzyLookupPinyin: string = '';
  word: string = '';
  frequency: number = 0;
  digits: string = '';

  constructor(pinyin: string, lookupPinyin: string, fuzzyLookupPinyin: string, word: string, frequency: number,
    digits: string) {
    this.pinyin = pinyin;
    this.lookupPinyin = lookupPinyin;
    this.fuzzyLookupPinyin = fuzzyLookupPinyin;
    this.word = word;
    this.frequency = frequency;
    this.digits = digits;
  }
}

export class PinyinCandidate {
  word: string = '';
  displayWord: string = '';
  pinyin: string = '';
  frequency: number = 0;
  source: number = CandidateSource.DICTIONARY;

  constructor(word: string, pinyin: string, frequency: number, source: number) {
    this.word = word;
    this.displayWord = word;
    this.pinyin = pinyin;
    this.frequency = frequency;
    this.source = source;
  }
}

class PinyinSegmentNode {
  text: string = '';
  score: number = 0;
  wordCount: number = 0;

  constructor(text: string, score: number, wordCount: number) {
    this.text = text;
    this.score = score;
    this.wordCount = wordCount;
  }
}

class PinyinNamePair {
  pinyin: string = '';
  text: string = '';

  constructor(pinyin: string, text: string) {
    this.pinyin = pinyin;
    this.text = text;
  }
}

const COMMON_SURNAMES: Array<PinyinNamePair> = [
  new PinyinNamePair('li', '李'), new PinyinNamePair('wang', '王'), new PinyinNamePair('zhang', '张'),
  new PinyinNamePair('liu', '刘'), new PinyinNamePair('chen', '陈'), new PinyinNamePair('yang', '杨'),
  new PinyinNamePair('zhao', '赵'), new PinyinNamePair('huang', '黄'), new PinyinNamePair('zhou', '周'),
  new PinyinNamePair('wu', '吴'), new PinyinNamePair('xu', '徐'), new PinyinNamePair('sun', '孙'),
  new PinyinNamePair('hu', '胡'), new PinyinNamePair('zhu', '朱'), new PinyinNamePair('gao', '高'),
  new PinyinNamePair('lin', '林'), new PinyinNamePair('he', '何'), new PinyinNamePair('guo', '郭'),
  new PinyinNamePair('ma', '马'), new PinyinNamePair('luo', '罗'), new PinyinNamePair('liang', '梁'),
  new PinyinNamePair('song', '宋'), new PinyinNamePair('zheng', '郑'), new PinyinNamePair('xie', '谢'),
  new PinyinNamePair('han', '韩'), new PinyinNamePair('tang', '唐'), new PinyinNamePair('feng', '冯'),
  new PinyinNamePair('yu', '于'), new PinyinNamePair('dong', '董'), new PinyinNamePair('xiao', '萧'),
  new PinyinNamePair('cheng', '程'), new PinyinNamePair('cao', '曹'), new PinyinNamePair('yuan', '袁'),
  new PinyinNamePair('deng', '邓'), new PinyinNamePair('fu', '傅'), new PinyinNamePair('shen', '沈'),
  new PinyinNamePair('zeng', '曾'), new PinyinNamePair('peng', '彭'), new PinyinNamePair('lv', '吕'),
  new PinyinNamePair('su', '苏'), new PinyinNamePair('lu', '卢'), new PinyinNamePair('jiang', '蒋'),
  new PinyinNamePair('cai', '蔡'), new PinyinNamePair('jia', '贾'), new PinyinNamePair('ding', '丁'),
  new PinyinNamePair('wei', '魏'), new PinyinNamePair('xue', '薛'), new PinyinNamePair('ye', '叶'),
  new PinyinNamePair('yan', '阎'), new PinyinNamePair('pan', '潘'), new PinyinNamePair('du', '杜'),
  new PinyinNamePair('dai', '戴'), new PinyinNamePair('xia', '夏'), new PinyinNamePair('zhong', '钟'),
  new PinyinNamePair('tian', '田'), new PinyinNamePair('ren', '任'), new PinyinNamePair('fan', '范'),
  new PinyinNamePair('fang', '方'), new PinyinNamePair('shi', '石'), new PinyinNamePair('yao', '姚'),
  new PinyinNamePair('tan', '谭'), new PinyinNamePair('liao', '廖'), new PinyinNamePair('zou', '邹'),
  new PinyinNamePair('xiong', '熊'), new PinyinNamePair('jin', '金'), new PinyinNamePair('hao', '郝'),
  new PinyinNamePair('kong', '孔'), new PinyinNamePair('bai', '白'), new PinyinNamePair('cui', '崔'),
  new PinyinNamePair('kang', '康'), new PinyinNamePair('mao', '毛'), new PinyinNamePair('qiu', '邱'),
  new PinyinNamePair('qin', '秦'), new PinyinNamePair('jiang', '江'), new PinyinNamePair('gu', '顾'),
  new PinyinNamePair('hou', '侯'), new PinyinNamePair('shao', '邵'), new PinyinNamePair('meng', '孟'),
  new PinyinNamePair('long', '龙'), new PinyinNamePair('wan', '万'), new PinyinNamePair('duan', '段'),
  new PinyinNamePair('lei', '雷'), new PinyinNamePair('qian', '钱'), new PinyinNamePair('yin', '尹'),
  new PinyinNamePair('ouyang', '欧阳'), new PinyinNamePair('situ', '司徒'), new PinyinNamePair('sima', '司马'),
  new PinyinNamePair('shangguan', '上官'), new PinyinNamePair('zhuge', '诸葛'),
  new PinyinNamePair('dongfang', '东方')
];

export class PinyinEngine {
  private entries: Array<PinyinDictionaryEntry> = [];
  private sortedPinyinEntries: Array<PinyinDictionaryEntry> = [];
  private sortedFuzzyEntries: Array<PinyinDictionaryEntry> = [];
  private sortedDigitEntries: Array<PinyinDictionaryEntry> = [];
  private exactIndex: Map<string, Array<PinyinDictionaryEntry>> = new Map<string, Array<PinyinDictionaryEntry>>();
  private charPinyinIndex: Map<string, string> = new Map<string, string>();
  private charPinyinScoreIndex: Map<string, number> = new Map<string, number>();
  private maxLookupPinyinLength: number = 0;
  private loaded: boolean = false;
  private composing: string = '';
  private candidates: Array<PinyinCandidate> = [];
  private traditionalTransliterator: i18n.Transliterator | undefined = undefined;
  private traditionalTransliteratorChecked: boolean = false;

  public loadFromResource(resourceMgr: resourceManager.ResourceManager): void {
    if (this.loaded) {
      return;
    }
    this.entries = [];
    this.charPinyinIndex.clear();
    this.charPinyinScoreIndex.clear();
    for (let i: number = 0; i < RAW_DICT_PATHS.length; i++) {
      try {
        let content: Uint8Array = resourceMgr.getRawFileContentSync(RAW_DICT_PATHS[i]);
        let decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
        let text: string = decoder.decodeToString(content);
        this.loadFromText(text);
        text = '';
        content = new Uint8Array(0);
      } catch (e) {
        hilog.error(0x0000, TAG, 'dictionary file load failed');
      }
    }
    if (this.entries.length === 0) {
      this.loadFallbackEntries();
    }
    this.buildIndexes();
    this.loaded = true;
    hilog.info(0x0000, TAG, 'dictionary loaded');
    this.publish();
  }

  public inputCode(code: string, layoutMode: number): void {
    if (code.length === 0) {
      return;
    }
    if (this.composing.length >= MAX_COMPOSING_LENGTH) {
      return;
    }
    this.composing = this.composing + code.toLowerCase();
    this.refreshCandidates(layoutMode);
    this.publish();
  }

  public removeLast(layoutMode: number): boolean {
    if (this.composing.length === 0) {
      return false;
    }
    this.composing = this.composing.substring(0, this.composing.length - 1);
    this.refreshCandidates(layoutMode);
    this.publish();
    return true;
  }

  public clear(): void {
    this.composing = '';
    this.candidates = [];
    this.publish();
  }

  public refreshForSettings(): void {
    if (this.composing.length === 0) {
      return;
    }
    this.refreshCandidates(SettingsStore.getLayoutMode());
    this.publish();
  }

  public hasComposition(): boolean {
    return this.composing.length > 0;
  }

  public getComposing(): string {
    return this.composing;
  }

  public getCandidate(index: number): PinyinCandidate | undefined {
    if (index < 0 || index >= this.candidates.length) {
      return undefined;
    }
    return this.candidates[index];
  }

  public commitCandidate(index: number): string {
    let result: string = '';
    let candidate: PinyinCandidate | undefined = this.getCandidate(index);
    if (candidate !== undefined) {
      result = candidate.word;
      SettingsStore.bumpRecentWord(candidate.word);
    } else if (this.composing.length > 0) {
      result = this.fallbackComposingText();
    }
    if (SettingsStore.getSettings().traditionalInputEnabled) {
      result = this.toTraditional(result);
    }
    this.clear();
    return result;
  }

  private loadFromText(text: string): void {
    let lineStart: number = 0;
    while (lineStart < text.length) {
      let lineEnd: number = text.indexOf('\n', lineStart);
      if (lineEnd < 0) {
        lineEnd = text.length;
      }
      this.loadLine(text.substring(lineStart, lineEnd).trim());
      lineStart = lineEnd + 1;
    }
  }

  private loadLine(line: string): void {
    if (line.length === 0) {
      return;
    }
    if (line.startsWith('#') || line === '---' || line === '...') {
      return;
    }
    let firstTab: number = line.indexOf('\t');
    if (firstTab < 0) {
      return;
    }
    let secondTab: number = line.indexOf('\t', firstTab + 1);
    let firstValue: string = line.substring(0, firstTab).trim();
    let secondValue: string = '';
    let weightText: string = '1';
    if (secondTab < 0) {
      secondValue = line.substring(firstTab + 1).trim();
    } else {
      secondValue = line.substring(firstTab + 1, secondTab).trim();
      weightText = line.substring(secondTab + 1).trim();
    }
    if (firstValue.length === 0 || secondValue.length === 0) {
      return;
    }
    let pinyin: string = '';
    let word: string = '';
    let frequency: number = 1;
    if (this.isPinyinCode(firstValue)) {
      pinyin = firstValue.toLowerCase();
      word = secondValue;
    } else if (this.isPinyinCode(secondValue)) {
      pinyin = secondValue.toLowerCase();
      word = firstValue;
    } else if (secondTab < 0 && this.isNumberText(secondValue)) {
      pinyin = this.inferWordPinyin(firstValue);
      word = firstValue;
      frequency = parseInt(secondValue);
    } else {
      return;
    }
    if (secondTab >= 0) {
      frequency = parseInt(weightText);
    }
    if (Number.isNaN(frequency)) {
      frequency = 1;
    }
    this.addDictionaryEntry(pinyin, word, frequency);
  }

  private addDictionaryEntry(pinyin: string, word: string, frequency: number): void {
    let lookupPinyin: string = this.normalizePinyin(pinyin);
    if (lookupPinyin.length > 0 && word.length > 0 && !Number.isNaN(frequency)) {
      this.entries.push(new PinyinDictionaryEntry(pinyin, lookupPinyin, this.toFuzzyPinyin(lookupPinyin), word,
        frequency,
        this.pinyinToDigits(lookupPinyin)));
      this.updateCharPinyinIndex(word, pinyin, frequency);
    }
  }

  private loadFallbackEntries(): void {
    this.entries = [];
    this.addFallbackEntry('ni', '你', 90000);
    this.addFallbackEntry('hao', '好', 88000);
    this.addFallbackEntry('nihao', '你好', 120000);
    this.addFallbackEntry('wo', '我', 98000);
    this.addFallbackEntry('women', '我们', 130000);
    this.addFallbackEntry('shurufa', '输入法', 112000);
    this.addFallbackEntry('pinyin', '拼音', 92000);
  }

  private addFallbackEntry(pinyin: string, word: string, frequency: number): void {
    this.addDictionaryEntry(pinyin, word, frequency);
  }

  private updateCharPinyinIndex(word: string, pinyin: string, frequency: number): void {
    if (word.length !== 1) {
      return;
    }
    let lookupPinyin: string = this.normalizePinyin(pinyin);
    if (lookupPinyin.length === 0) {
      return;
    }
    let storedScore: number | undefined = this.charPinyinScoreIndex.get(word);
    if (storedScore === undefined || frequency > storedScore) {
      this.charPinyinIndex.set(word, lookupPinyin);
      this.charPinyinScoreIndex.set(word, frequency);
    }
  }

  private inferWordPinyin(word: string): string {
    let result: string = '';
    for (let i: number = 0; i < word.length; i++) {
      let charText: string = word.charAt(i);
      let pinyin: string | undefined = this.charPinyinIndex.get(charText);
      if (pinyin === undefined || pinyin.length === 0) {
        return '';
      }
      result = result + pinyin;
    }
    return result;
  }

  private buildIndexes(): void {
    this.exactIndex.clear();
    this.maxLookupPinyinLength = 0;
    for (let i: number = 0; i < this.entries.length; i++) {
      let entry: PinyinDictionaryEntry = this.entries[i];
      if (entry.lookupPinyin.length > this.maxLookupPinyinLength) {
        this.maxLookupPinyinLength = entry.lookupPinyin.length;
      }
      this.addToExactIndex(entry);
    }
    this.sortedPinyinEntries = this.entries.slice(0);
    this.sortedFuzzyEntries = this.entries.slice(0);
    this.sortedDigitEntries = this.entries.slice(0);
    this.sortedPinyinEntries.sort((left: PinyinDictionaryEntry, right: PinyinDictionaryEntry): number => {
      return this.compareString(left.lookupPinyin, right.lookupPinyin);
    });
    this.sortedFuzzyEntries.sort((left: PinyinDictionaryEntry, right: PinyinDictionaryEntry): number => {
      return this.compareString(left.fuzzyLookupPinyin, right.fuzzyLookupPinyin);
    });
    this.sortedDigitEntries.sort((left: PinyinDictionaryEntry, right: PinyinDictionaryEntry): number => {
      return this.compareString(left.digits, right.digits);
    });
  }

  private addToExactIndex(entry: PinyinDictionaryEntry): void {
    let entries: Array<PinyinDictionaryEntry> | undefined = this.exactIndex.get(entry.lookupPinyin);
    if (entries === undefined) {
      entries = [];
      this.exactIndex.set(entry.lookupPinyin, entries);
    }
    entries.push(entry);
  }

  private refreshCandidates(layoutMode: number): void {
    this.candidates = [];
    if (this.composing.length === 0) {
      return;
    }
    this.addMatchingCandidates(layoutMode);
    this.addSegmentedCandidate(layoutMode);
    this.addNameCandidate(layoutMode);
    if (this.candidates.length === 0 && (layoutMode === KeyboardLayoutMode.QWERTY26 ||
      layoutMode === KeyboardLayoutMode.XIAOHE_SHUANGPIN) &&
      SettingsStore.getSettings().mixedInputEnabled) {
      this.candidates.push(new PinyinCandidate(this.fallbackComposingText(), this.lookupQuery(layoutMode), 1,
        CandidateSource.RAW_CODE));
    }
    this.candidates.sort((left: PinyinCandidate, right: PinyinCandidate): number => {
      return this.compareCandidates(left, right);
    });
    if (this.candidates.length > MAX_CANDIDATE_COUNT) {
      this.candidates.splice(MAX_CANDIDATE_COUNT, this.candidates.length - MAX_CANDIDATE_COUNT);
    }
  }

  private addMatchingCandidates(layoutMode: number): void {
    if (layoutMode === KeyboardLayoutMode.T9) {
      this.addDigitPrefixCandidates(this.composing);
      return;
    }
    let query: string = this.lookupQuery(layoutMode);
    if (query.length === 0) {
      return;
    }
    if (SettingsStore.getSettings().fuzzyPinyinEnabled) {
      this.addFuzzyPrefixCandidates(this.toFuzzyPinyin(query));
      return;
    }
    this.addPinyinPrefixCandidates(query);
  }

  private addPinyinPrefixCandidates(prefix: string): void {
    let start: number = this.lowerBoundPinyin(prefix);
    for (let i: number = start; i < this.sortedPinyinEntries.length; i++) {
      let entry: PinyinDictionaryEntry = this.sortedPinyinEntries[i];
      if (!this.hasPrefix(entry.lookupPinyin, prefix)) {
        return;
      }
      this.addCandidate(entry);
    }
  }

  private addFuzzyPrefixCandidates(prefix: string): void {
    let start: number = this.lowerBoundFuzzy(prefix);
    for (let i: number = start; i < this.sortedFuzzyEntries.length; i++) {
      let entry: PinyinDictionaryEntry = this.sortedFuzzyEntries[i];
      if (!this.hasPrefix(entry.fuzzyLookupPinyin, prefix)) {
        return;
      }
      this.addCandidate(entry);
    }
  }

  private addDigitPrefixCandidates(prefix: string): void {
    let start: number = this.lowerBoundDigits(prefix);
    for (let i: number = start; i < this.sortedDigitEntries.length; i++) {
      let entry: PinyinDictionaryEntry = this.sortedDigitEntries[i];
      if (!this.hasPrefix(entry.digits, prefix)) {
        return;
      }
      this.addCandidate(entry);
    }
  }

  private addCandidate(entry: PinyinDictionaryEntry): void {
    let score: number = entry.frequency + SettingsStore.getRecentBoost(entry.word);
    if (this.isLikelyChineseName(entry.word)) {
      score = score + NAME_CANDIDATE_BONUS;
    }
    this.addPreparedCandidate(new PinyinCandidate(entry.word, entry.pinyin, score, CandidateSource.DICTIONARY));
  }

  private addSegmentedCandidate(layoutMode: number): void {
    if (layoutMode !== KeyboardLayoutMode.QWERTY26 && layoutMode !== KeyboardLayoutMode.XIAOHE_SHUANGPIN) {
      return;
    }
    let candidate: PinyinCandidate | undefined = this.buildSegmentedCandidate(layoutMode);
    if (candidate !== undefined) {
      this.addPreparedCandidate(candidate);
    }
  }

  private addNameCandidate(layoutMode: number): void {
    if (layoutMode !== KeyboardLayoutMode.QWERTY26 && layoutMode !== KeyboardLayoutMode.XIAOHE_SHUANGPIN) {
      return;
    }
    let candidate: PinyinCandidate | undefined = this.buildNameCandidate(layoutMode);
    if (candidate !== undefined) {
      this.addPreparedCandidate(candidate);
    }
  }

  private addPreparedCandidate(candidate: PinyinCandidate): void {
    candidate.displayWord = this.displayCandidateWord(candidate.word);
    for (let i: number = 0; i < this.candidates.length; i++) {
      let existing: PinyinCandidate = this.candidates[i];
      if (existing.word === candidate.word) {
        if (candidate.frequency > existing.frequency) {
          existing.frequency = candidate.frequency;
          existing.pinyin = candidate.pinyin;
          existing.source = candidate.source;
        }
        existing.displayWord = candidate.displayWord;
        return;
      }
    }
    this.candidates.push(candidate);
    this.trimCandidatePool();
  }

  private trimCandidatePool(): void {
    if (this.candidates.length <= MAX_CANDIDATE_POOL) {
      return;
    }
    let worstIndex: number = 0;
    for (let i: number = 1; i < this.candidates.length; i++) {
      let candidate: PinyinCandidate = this.candidates[i];
      if (this.compareCandidates(candidate, this.candidates[worstIndex]) > 0) {
        worstIndex = i;
      }
    }
    this.candidates.splice(worstIndex, 1);
  }

  private compareCandidates(left: PinyinCandidate, right: PinyinCandidate): number {
    if (SettingsStore.getSettings().singleCharPriorityEnabled) {
      let leftSingle: boolean = left.word.length === 1;
      let rightSingle: boolean = right.word.length === 1;
      if (leftSingle && !rightSingle) {
        return -1;
      }
      if (!leftSingle && rightSingle) {
        return 1;
      }
    }
    if (left.frequency !== right.frequency) {
      return right.frequency - left.frequency;
    }
    if (left.word.length !== right.word.length) {
      return left.word.length - right.word.length;
    }
    return this.compareString(left.word, right.word);
  }

  private buildSegmentedCandidate(layoutMode: number): PinyinCandidate | undefined {
    let code: string = this.lookupQuery(layoutMode);
    if (code.length === 0) {
      return undefined;
    }
    let nodes: Array<PinyinSegmentNode | undefined> = [];
    for (let i: number = 0; i <= code.length; i++) {
      nodes.push(undefined);
    }
    nodes[0] = new PinyinSegmentNode('', 0, 0);
    for (let start: number = 0; start < code.length; start++) {
      let baseNode: PinyinSegmentNode | undefined = nodes[start];
      if (baseNode === undefined) {
        continue;
      }
      let base: PinyinSegmentNode = baseNode;
      let maxEnd: number = start + this.maxLookupPinyinLength;
      if (maxEnd > code.length) {
        maxEnd = code.length;
      }
      for (let end: number = start + 1; end <= maxEnd; end++) {
        let entry: PinyinDictionaryEntry | undefined = this.getBestExactEntry(code.substring(start, end));
        if (entry === undefined) {
          continue;
        }
        let nextScore: number = base.score + this.segmentEntryScore(entry);
        let nextWordCount: number = base.wordCount + 1;
        let currentNode: PinyinSegmentNode | undefined = nodes[end];
        if (currentNode === undefined || nextWordCount < currentNode.wordCount ||
          (nextWordCount === currentNode.wordCount && nextScore > currentNode.score)) {
          nodes[end] = new PinyinSegmentNode(base.text + entry.word, nextScore, nextWordCount);
        }
      }
    }
    let finalNode: PinyinSegmentNode | undefined = nodes[code.length];
    if (finalNode === undefined || finalNode.wordCount < 2) {
      return undefined;
    }
    return new PinyinCandidate(finalNode.text, code, finalNode.score + SEGMENT_SENTENCE_BONUS,
      CandidateSource.SEGMENTED);
  }

  private buildNameCandidate(layoutMode: number): PinyinCandidate | undefined {
    let code: string = this.lookupQuery(layoutMode);
    if (code.length < 4 || code.length > 18) {
      return undefined;
    }
    let bestText: string = '';
    let bestScore: number = 0;
    for (let i: number = 0; i < COMMON_SURNAMES.length; i++) {
      let surname: PinyinNamePair = COMMON_SURNAMES[i];
      if (!this.hasPrefix(code, surname.pinyin) || code.length <= surname.pinyin.length) {
        continue;
      }
      let rest: string = code.substring(surname.pinyin.length);
      let oneCharName: string = this.getBestGivenNameChar(rest);
      if (oneCharName.length > 0) {
        let score: number = NAME_SYNTHETIC_SCORE + this.getGivenNameCharScore(rest, oneCharName);
        if (score > bestScore) {
          bestText = surname.text + oneCharName;
          bestScore = score;
        }
      }
      for (let cut: number = 1; cut < rest.length; cut++) {
        let firstCode: string = rest.substring(0, cut);
        let secondCode: string = rest.substring(cut);
        let firstName: string = this.getBestGivenNameChar(firstCode);
        let secondName: string = this.getBestGivenNameChar(secondCode);
        if (firstName.length === 0 || secondName.length === 0) {
          continue;
        }
        let score: number = NAME_SYNTHETIC_SCORE + 1000 +
          this.getGivenNameCharScore(firstCode, firstName) + this.getGivenNameCharScore(secondCode, secondName);
        if (score > bestScore) {
          bestText = surname.text + firstName + secondName;
          bestScore = score;
        }
      }
    }
    if (bestText.length === 0) {
      return undefined;
    }
    return new PinyinCandidate(bestText, code, bestScore, CandidateSource.NAME);
  }

  private getBestExactEntry(code: string): PinyinDictionaryEntry | undefined {
    let entries: Array<PinyinDictionaryEntry> | undefined = this.exactIndex.get(code);
    if (entries === undefined || entries.length === 0) {
      return undefined;
    }
    let bestEntry: PinyinDictionaryEntry = entries[0];
    let bestScore: number = this.segmentEntryScore(bestEntry);
    for (let i: number = 1; i < entries.length; i++) {
      let entry: PinyinDictionaryEntry = entries[i];
      let score: number = this.segmentEntryScore(entry);
      if (score > bestScore) {
        bestEntry = entry;
        bestScore = score;
      }
    }
    return bestEntry;
  }

  private segmentEntryScore(entry: PinyinDictionaryEntry): number {
    let score: number = entry.frequency + SettingsStore.getRecentBoost(entry.word);
    score = score + entry.word.length * SEGMENT_CHAR_BONUS;
    if (entry.word.length > 1) {
      score = score + SEGMENT_WORD_BONUS;
    }
    return score;
  }

  private isLikelyChineseName(word: string): boolean {
    if (word.length < 2 || word.length > 4) {
      return false;
    }
    for (let i: number = 0; i < COMMON_SURNAMES.length; i++) {
      let surname: PinyinNamePair = COMMON_SURNAMES[i];
      if (this.hasPrefix(word, surname.text) && word.length > surname.text.length) {
        return this.isCommonGivenNameText(word.substring(surname.text.length));
      }
    }
    return false;
  }

  private getBestGivenNameChar(code: string): string {
    let entries: Array<PinyinDictionaryEntry> | undefined = this.exactIndex.get(code);
    if (entries === undefined || entries.length === 0) {
      return '';
    }
    let bestText: string = '';
    let bestScore: number = 0;
    for (let i: number = 0; i < entries.length; i++) {
      let entry: PinyinDictionaryEntry = entries[i];
      if (entry.word.length !== 1) {
        continue;
      }
      if (!this.isCommonGivenNameChar(entry.word)) {
        continue;
      }
      let score: number = this.getGivenNameCharScore(code, entry.word);
      if (score > bestScore) {
        bestText = entry.word;
        bestScore = score;
      }
    }
    return bestText;
  }

  private getGivenNameCharScore(code: string, word: string): number {
    let entries: Array<PinyinDictionaryEntry> | undefined = this.exactIndex.get(code);
    let score: number = 0;
    if (entries !== undefined) {
      for (let i: number = 0; i < entries.length; i++) {
        let entry: PinyinDictionaryEntry = entries[i];
        if (entry.word === word && entry.frequency > score) {
          score = entry.frequency;
        }
      }
    }
    if (score > GIVEN_NAME_BASE_SCORE_LIMIT) {
      score = GIVEN_NAME_BASE_SCORE_LIMIT;
    }
    if (COMMON_GIVEN_NAME_CHARS.indexOf(word) >= 0) {
      score = score + GIVEN_NAME_CHAR_BONUS;
    }
    return score;
  }

  private isCommonGivenNameText(value: string): boolean {
    if (value.length === 0 || value.length > 2) {
      return false;
    }
    for (let i: number = 0; i < value.length; i++) {
      if (!this.isCommonGivenNameChar(value.charAt(i))) {
        return false;
      }
    }
    return true;
  }

  private isCommonGivenNameChar(value: string): boolean {
    return COMMON_GIVEN_NAME_CHARS.indexOf(value) >= 0;
  }

  private lowerBoundPinyin(prefix: string): number {
    let low: number = 0;
    let high: number = this.sortedPinyinEntries.length;
    while (low < high) {
      let mid: number = Math.floor((low + high) / 2);
      if (this.compareString(this.sortedPinyinEntries[mid].lookupPinyin, prefix) < 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  private lowerBoundFuzzy(prefix: string): number {
    let low: number = 0;
    let high: number = this.sortedFuzzyEntries.length;
    while (low < high) {
      let mid: number = Math.floor((low + high) / 2);
      if (this.compareString(this.sortedFuzzyEntries[mid].fuzzyLookupPinyin, prefix) < 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  private lowerBoundDigits(prefix: string): number {
    let low: number = 0;
    let high: number = this.sortedDigitEntries.length;
    while (low < high) {
      let mid: number = Math.floor((low + high) / 2);
      if (this.compareString(this.sortedDigitEntries[mid].digits, prefix) < 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  private compareString(left: string, right: string): number {
    if (left < right) {
      return -1;
    }
    if (left > right) {
      return 1;
    }
    return 0;
  }

  private hasPrefix(value: string, prefix: string): boolean {
    if (prefix.length === 0 || prefix.length > value.length) {
      return false;
    }
    return value.substring(0, prefix.length) === prefix;
  }

  private publish(): void {
    AppStorage.setOrCreate('ime.composing', this.composing);
    AppStorage.setOrCreate('ime.candidates', this.candidates);
  }

  private lookupQuery(layoutMode: number): string {
    if (layoutMode === KeyboardLayoutMode.XIAOHE_SHUANGPIN) {
      return this.normalizePinyin(ShuangpinDecoder.decode(this.composing));
    }
    return this.normalizePinyin(this.composing);
  }

  private fallbackComposingText(): string {
    if (SettingsStore.getLayoutMode() === KeyboardLayoutMode.XIAOHE_SHUANGPIN) {
      return ShuangpinDecoder.decode(this.composing);
    }
    return this.composing;
  }

  private pinyinToDigits(pinyin: string): string {
    let result: string = '';
    for (let i: number = 0; i < pinyin.length; i++) {
      result = result + this.letterToDigit(pinyin.charAt(i));
    }
    return result;
  }

  private letterToDigit(letter: string): string {
    if (letter === 'a' || letter === 'b' || letter === 'c') {
      return '2';
    }
    if (letter === 'd' || letter === 'e' || letter === 'f') {
      return '3';
    }
    if (letter === 'g' || letter === 'h' || letter === 'i') {
      return '4';
    }
    if (letter === 'j' || letter === 'k' || letter === 'l') {
      return '5';
    }
    if (letter === 'm' || letter === 'n' || letter === 'o') {
      return '6';
    }
    if (letter === 'p' || letter === 'q' || letter === 'r' || letter === 's') {
      return '7';
    }
    if (letter === 't' || letter === 'u' || letter === 'v') {
      return '8';
    }
    if (letter === 'w' || letter === 'x' || letter === 'y' || letter === 'z') {
      return '9';
    }
    return '';
  }

  private normalizePinyin(value: string): string {
    let result: string = value.toLowerCase();
    result = result.split("'").join('');
    result = result.split(' ').join('');
    result = result.split('-').join('');
    result = result.split('\u00fc').join('v');
    result = result.split('\u00dc').join('v');
    result = result.split('u:').join('v');
    return result;
  }

  private isPinyinCode(value: string): boolean {
    let normalized: string = this.normalizePinyin(value);
    if (normalized.length === 0) {
      return false;
    }
    for (let i: number = 0; i < normalized.length; i++) {
      let code: number = normalized.charCodeAt(i);
      if (code < 97 || code > 122) {
        return false;
      }
    }
    return true;
  }

  private isNumberText(value: string): boolean {
    if (value.length === 0) {
      return false;
    }
    for (let i: number = 0; i < value.length; i++) {
      let code: number = value.charCodeAt(i);
      if (code < 48 || code > 57) {
        return false;
      }
    }
    return true;
  }

  private toFuzzyPinyin(value: string): string {
    let result: string = value;
    result = result.split('zh').join('z');
    result = result.split('ch').join('c');
    result = result.split('sh').join('s');
    return result;
  }

  private toTraditional(value: string): string {
    let transliterator: i18n.Transliterator | undefined = this.getTraditionalTransliterator();
    if (transliterator !== undefined) {
      try {
        return transliterator.transform(value);
      } catch (e) {
        hilog.error(0x0000, TAG, 'traditional transliteration failed');
      }
    }
    let result: string = value;
    result = result.split('输入法').join('輸入法');
    result = result.split('输入').join('輸入');
    result = result.split('键盘').join('鍵盤');
    result = result.split('候选').join('候選');
    result = result.split('我们').join('我們');
    result = result.split('中国').join('中國');
    result = result.split('国').join('國');
    result = result.split('们').join('們');
    return result;
  }

  private displayCandidateWord(value: string): string {
    if (!SettingsStore.getSettings().traditionalInputEnabled) {
      return value;
    }
    return this.toTraditional(value);
  }

  private getTraditionalTransliterator(): i18n.Transliterator | undefined {
    if (this.traditionalTransliteratorChecked) {
      return this.traditionalTransliterator;
    }
    this.traditionalTransliteratorChecked = true;
    let preferredIds: Array<string> = ['Simplified-Traditional', 'Hans-Hant'];
    try {
      let availableIds: Array<string> = i18n.Transliterator.getAvailableIDs();
      for (let preferredIndex: number = 0; preferredIndex < preferredIds.length; preferredIndex++) {
        let preferredId: string = preferredIds[preferredIndex];
        for (let availableIndex: number = 0; availableIndex < availableIds.length; availableIndex++) {
          if (availableIds[availableIndex] === preferredId) {
            this.traditionalTransliterator = i18n.Transliterator.getInstance(preferredId);
            hilog.info(0x0000, TAG, 'traditional transliterator ready: %{public}s', preferredId);
            return this.traditionalTransliterator;
          }
        }
      }
      hilog.warn(0x0000, TAG, 'traditional transliterator is unavailable, using compatibility mapping');
    } catch (e) {
      hilog.error(0x0000, TAG, 'initialize traditional transliterator failed');
    }
    return undefined;
  }
}

export const pinyinEngine: PinyinEngine = new PinyinEngine();
