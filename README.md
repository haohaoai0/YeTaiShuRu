# 液态输入法

液态输入法是一个面向 HarmonyOS 的 ArkTS 输入法应用。它提供通透的键盘外观、本地拼音候选、九宫格和小鹤双拼等输入方式，以及可在设置页调整的键盘布局、反馈和皮肤选项。

> 当前版本：`1.0.0`
> 包名：`com.my.liquidime`

## 功能

- 26 键、9 键和小鹤双拼输入布局，支持中英文切换、模糊拼音、中英混输、单字优先与繁体候选显示。
- 本地词库和候选排序；会依据最近选择的候选改善排序。
- 字母、数字、符号、表情、剪贴板与编辑键盘面板；表情面板记录最近使用项。
- 可调键盘高度、数字行、上滑输入、按键音、振动、按键气泡和长按延迟。
- 液态、青瓷、夜色、暖阳、彩虹和彩虹字预设皮肤，支持自定义背景色、按键色及相册背景图。
- 左右单手停靠、工具栏定制、回车发送和输入辅助选项。
- 长按空格的语音转文字入口，使用系统语音识别能力并申请麦克风权限。

## 系统与权限

工程的兼容 SDK 为 `6.1.0(23)`，目标 SDK 为 `26.0.0`。入口模块同时声明了手机和平板设备类型。

应用只声明下列运行时权限：

| 权限 | 用途 |
| --- | --- |
| `ohos.permission.VIBRATE` | 按键触感反馈 |
| `ohos.permission.MICROPHONE` | 长按空格进行语音转文字 |

剪贴板读取权限目前未在 `module.json5` 中启用；剪贴板面板在系统允许的范围内工作。

## 构建

1. 使用支持 HarmonyOS SDK `6.1.0(23)` 或更高兼容版本的 DevEco Studio 打开工程根目录。
2. 同步 OHPM 依赖，并为本机配置调试签名。仓库不会提交任何签名证书、描述文件或口令。
3. 选择 `entry` 模块的 `default` 产品，构建 Debug HAP。
4. 安装到手机或平板，在系统设置的输入法页面启用并切换到“液态输入法”。

也可以在已配置 DevEco CLI 的环境中执行：

```powershell
devecocli build
```

构建生成的 HAP、`build/`、`.hvigor/`、`oh_modules/` 和本地 IDE 配置均被忽略，不会进入仓库。

## 项目结构

```text
AppScope/                         应用级配置和图标资源
entry/src/main/ets/
  InputMethodExtensionAbility/    输入法扩展与键盘控制器
  components/                     各类键盘、候选栏和顶部工具栏
  model/                          拼音引擎、双拼解码和设置模型
  common/                         声音、语音输入与视觉样式工具
  pages/                          应用设置页与启用提示页
entry/src/main/resources/         多语言资源、主题与本地词库
THIRD_PARTY_NOTICES.md            第三方词库与参考实现归属说明
```

## 第三方内容

项目内置的部分中文词库和实现思路来自 Cassotis Lexicon、Rime Ice、OpenHarmony KikaInputMethod 示例及 he-pinyin-ime-hmos。完整来源和适用许可证见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

`third_party/` 仅保存本地开发时参考的上游仓库，不作为本项目 Git 仓库内容提交。

## 许可

本仓库暂未声明项目自身的开源许可证。使用、复制或分发前，请先确认项目维护者的授权，并遵守 `THIRD_PARTY_NOTICES.md` 中列出的第三方许可证。
