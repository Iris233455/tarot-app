# 📝 文本统一管理系统使用指南

## 🎯 概述

现在所有的文本内容都通过 `AppStrings` 类进行统一管理，实现了：
- ✅ **文本内容统一管理** - 所有界面文字集中管理
- ✅ **样式统一管理** - 字体、大小、粗细、颜色统一控制
- ✅ **一处修改，全局生效** - 修改样式立即应用到所有使用的地方

---

## 📁 文件结构

```
lib/core/l10n/
├── app_strings.dart          # 文本统一管理系统
└── app_localizations.dart    # 国际化框架（预留）
```

---

## 🎨 使用方法

### **方法 1: 使用预定义的样式化组件**

```dart
// 直接使用预定义的组件
AppStrings.homeDailyCardTitle        // "本日のカード" 主标题样式
AppStrings.homeTarotCalendarTitle    // "タロットカレンダー" 次标题样式
AppStrings.appNameTitle              // 应用名称标题
AppStrings.completeButton            // 完成按钮样式
AppStrings.cancelButton              // 取消按钮样式
AppStrings.errorMessage              // 错误消息样式
```

### **方法 2: 使用样式创建函数**

```dart
// 创建自定义样式的文本
AppStrings.createMainTitle('自定义标题', color: Colors.blue)
AppStrings.createSubTitle('自定义次标题', color: dynamicTokens.textPrimary)
AppStrings.createBodyText('正文内容')
AppStrings.createButtonText('按钮文字')
AppStrings.createErrorText('错误消息')
AppStrings.createSuccessText('成功消息')
```

### **方法 3: 仅使用文本内容**

```dart
// 仅获取文本内容，自定义样式
Text(
  AppStrings.homeDailyCard,
  style: YourCustomStyle(),
)
```

---

## 🎨 可用的样式类型

| 样式类型 | 函数名 | 字体大小 | 字体粗细 | 用途 |
|---------|--------|---------|---------|------|
| **主标题** | `createMainTitle` | HeadlineMedium (24px) | Black (w900) | 页面主标题 |
| **次标题** | `createSubTitle` | TitleLarge (20px) | Bold (w700) | 页面次标题 |
| **小标题** | `createSmallTitle` | TitleMedium (18px) | SemiBold (w600) | 小节标题 |
| **正文** | `createBodyText` | BodyMedium (14px) | Regular (w400) | 普通正文 |
| **强调文本** | `createEmphasisText` | BodyMedium (14px) | Medium (w500) | 重要信息 |
| **按钮文字** | `createButtonText` | BodyMedium (14px) | Bold (w700) | 按钮文字 |
| **说明文字** | `createCaptionText` | Caption (12px) | Regular (w400) | 辅助说明 |
| **错误消息** | `createErrorText` | BodySmall (12px) | Medium (w500) | 错误提示 |
| **成功消息** | `createSuccessText` | BodySmall (12px) | Medium (w500) | 成功提示 |

---

## 🔧 如何统一调整样式

### **调整字体大小**
修改 `lib/themes/tokens.dart` 中的字体大小定义：
```dart
static const double fontSizeHeadlineMedium = 28.0;  // 从 24.0 改为 28.0
```

### **调整字体粗细**
修改 `lib/themes/tokens.dart` 中的字体粗细定义：
```dart
static const FontWeight fontWeightBlack = FontWeight.w800;  // 从 w900 改为 w800
```

### **调整字体家族**
修改 `lib/themes/tokens.dart` 中的字体家族定义：
```dart
static const String fontFamilyHeadline = 'YourCustomFont';  // 更换字体
```

### **调整文本颜色**
修改 `lib/themes/tokens.dart` 或 `lib/themes/dynamic_tokens.dart` 中的颜色定义：
```dart
static const Color textPrimary = Color(0xFF000000);  // 更换主文本颜色
```

---

## 📋 已管理的文本内容

### **✅ 系统界面文本 (43处)**
- 系统主标题: `appName`, `appSubtitle`
- 首页相关: `homeDailyCard`, `homeTarotCalendar`, `homeTodayMessage`
- 占卜流程: `readingSelectSpread`, `readingTarotReading`, `readingExplanation`
- 兑换码页面: `redemptionTitle`, `redemptionAbout`, `redemptionInputLabel`
- 订阅相关: `subscriptionPremiumPlan`, `subscriptionBenefits`
- 设置页面: `settingsDeckSelection`, `settingsBackDesign`, `settingsMusic`
- 按钮文字: `buttonComplete`, `buttonCancel`, `buttonConfirm`
- 状态消息: `messageLoading`, `messageError`, `messageAlreadyDrawnToday`

### **✅ 卡牌内容文本 (100%)**
- 卡牌数据通过 JSON 文件管理
- 位置: `assets/data/rider_waite_cards.json`

### **✅ 样式相关 (100%)**
- 通过 Design Token 系统管理
- 位置: `lib/themes/tokens.dart`, `lib/themes/dynamic_tokens.dart`

---

## 🚀 实际应用示例

### **修改前 (硬编码)**
```dart
Text(
  '本日のカード',
  style: TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w900,
    fontFamily: 'NotoSansJP',
    color: Colors.black,
  ),
)
```

### **修改后 (统一管理)**
```dart
// 方法1: 使用预定义组件
AppStrings.homeDailyCardTitle

// 方法2: 使用创建函数
AppStrings.createMainTitle(
  AppStrings.homeDailyCard,
  color: dynamicTokens.textPrimary,
)
```

---

## 🎯 优势总结

1. **🎨 样式统一**: 所有文本样式通过 Design Token 统一管理
2. **📝 内容集中**: 所有文本内容在一个文件中管理
3. **🔧 易于维护**: 修改一处，全局生效
4. **🌐 国际化准备**: 为未来多语言支持做好准备
5. **⚡ 开发效率**: 预定义组件提高开发速度
6. **🎯 类型安全**: 编译时检查，减少错误

---

## 📈 未来扩展

1. **多语言支持**: 基于现有结构添加英文、中文等
2. **主题切换**: 不同主题使用不同的文本样式
3. **动态字体**: 根据用户偏好调整字体大小
4. **A/B测试**: 轻松切换不同的文案版本

---

**🎉 现在你可以通过修改 Design Token 来统一调整所有文本的字体、样式、大小！**
