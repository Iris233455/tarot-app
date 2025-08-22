# Design Tokens 更新日志

> 记录塔罗牌应用设计令牌系统的所有修改和优化

---

## 📅 2025-01-21 - Design Token 系统重构与优化

### 🎯 **本次更新目标**
- 优化文本颜色层次，提升可读性
- 调整字体尺寸体系，完善排版层次
- 统一设计令牌引用，提高代码一致性
- 建立 Figma ↔ Flutter 双向同步机制

---

## 🔄 **主要修改内容**

### 1. **文本颜色系统重构** 
**文件**: `lib/themes/tokens.dart`, `lib/themes/dynamic_tokens.dart`, `lib/providers/theme_provider.dart`

#### **更新前:**
```dart
static const Color textPrimary = Color(0xFF4A4A4A);    // 主文本
static const Color textSecondary = Color(0xFF7A7A7A);  // 次文本
```

#### **更新后:**
```dart
static const Color textPrimary = Color(0xFF1A1A1A);    // 主文本（更深，提升可读性）
static const Color textSecondary = Color(0xFF4A4A4A);  // 次文本
static const Color textTertiary = Color(0xFF9E9E9E);   // 弱化或禁用文字颜色
static const Color textInverse = Color(0xFFFFFFFF);    // 深色背景下文字颜色
```

#### **影响范围:**
- ✅ 提升主文本对比度和可读性
- ✅ 建立完整的文本颜色层次
- ✅ 支持深色模式下的文字显示
- ✅ 为禁用状态提供专用颜色

---

### 2. **字体尺寸体系优化**
**文件**: `lib/themes/tokens.dart`, `lib/core/theme/app_theme.dart`

#### **更新前:**
```dart
// 字体尺寸不够精细，缺少中间层次
fontSizeXXLarge = 32.0    // Headline Large
fontSizeXLarge = 28.0     // Headline Medium  
fontSizeLarge = 20.0      // Title
fontSizeMedium = 16.0     // Body
```

#### **更新后:**
```dart
// 完整的字体尺寸体系
static const double fontSizeHeadlineLarge = 32.0;   // 大标题
static const double fontSizeHeadlineMedium = 24.0;  // 中标题 (28→24 调整)
static const double fontSizeTitleLarge = 20.0;      // 标题 (新增)
static const double fontSizeBodyLarge = 16.0;       // 正文大
static const double fontSizeBodyMedium = 14.0;      // 正文中
static const double fontSizeBodySmall = 12.0;       // 正文小
```

#### **影响范围:**
- ✅ Headline Medium 从 28px 调整到 24px，更协调
- ✅ 新增 Title Large (20px)，填补字体尺寸空隙
- ✅ 建立完整的字体尺寸梯度 (12-32px)
- ✅ 所有 TextTheme 映射已更新

---

### 3. **设计令牌统一化**
**文件**: `lib/core/theme/app_theme.dart`

#### **更新前:**
```dart
class AppTheme {
  // 硬编码的设计值，分散管理
  static const double fontSizeXXLarge = 32.0;
  static const double radiusM = 12.0;
  // ...各种分散的常量
}
```

#### **更新后:**
```dart
class AppTheme {
  // 统一引用 DesignTokens，集中管理
  static double get fontSizeHeadlineLarge => DesignTokens.fontSizeHeadlineLarge;
  static double get radiusMd => DesignTokens.radiusMd;
  // ...所有值都从 DesignTokens 引用
}
```

#### **影响范围:**
- ✅ 消除重复定义，单一数据源
- ✅ 修改设计令牌时自动同步所有组件
- ✅ 提高代码维护性和一致性
- ✅ 支持热更新设计令牌

---

### 4. **可视化工具增强**
**文件**: `lib/screens/dev/design_tokens_screen.dart`

#### **新增功能:**
- ✅ 显示新增的文本颜色层次 (Tertiary, Inverse)
- ✅ 展示更新后的字体尺寸体系
- ✅ 实时主题切换预览
- ✅ 完整的设计令牌展示面板

#### **访问方式:**
```
http://127.0.0.1:5174/#/design-tokens
```

---

### 5. **Figma 集成支持**
**文件**: `/Users/toshunmei/Desktop/Tarot/Tarot_Card_App/DesignSystem/design-tokens.json`

#### **创建内容:**
- ✅ Figma Tokens Studio 兼容的 JSON 格式
- ✅ 包含所有颜色、字体、间距、圆角、阴影令牌
- ✅ 支持 6 种预定义主题
- ✅ 可导入 Figma 进行设计同步

---

## 📂 **修改文件清单**

### **核心设计令牌文件:**
- `lib/themes/tokens.dart` - 基础设计令牌定义
- `lib/themes/dynamic_tokens.dart` - 动态主题令牌
- `lib/providers/theme_provider.dart` - 主题提供器
- `lib/core/theme/app_theme.dart` - 全局主题配置

### **可视化与工具:**
- `lib/screens/dev/design_tokens_screen.dart` - 设计令牌可视化页面
- `lib/routers/app_router.dart` - 路由配置（新增 /design-tokens）

### **外部集成:**
- `DesignSystem/design-tokens.json` - Figma 集成文件
- `DesignSystem/README.md` - Figma 使用指南

---

## 🎨 **使用指南**

### **1. 在代码中使用新的文本颜色:**
```dart
// 主文本 - 最高对比度
Text('重要内容', style: TextStyle(color: DesignTokens.textPrimary))

// 次文本 - 中等对比度  
Text('辅助信息', style: TextStyle(color: DesignTokens.textSecondary))

// 弱化文本 - 低对比度
Text('提示文字', style: TextStyle(color: DesignTokens.textTertiary))

// 深色背景文本
Container(
  color: Colors.black,
  child: Text('深色背景文本', style: TextStyle(color: DesignTokens.textInverse))
)
```

### **2. 使用新的字体尺寸:**
```dart
// 大标题
Text('大标题', style: TextStyle(fontSize: DesignTokens.fontSizeHeadlineLarge))

// 中标题 (更新后 24px)
Text('中标题', style: TextStyle(fontSize: DesignTokens.fontSizeHeadlineMedium))

// 新增的标题尺寸
Text('标题', style: TextStyle(fontSize: DesignTokens.fontSizeTitleLarge))
```

### **3. 主题切换测试:**
访问 `/design-tokens` 页面，使用右上角下拉菜单切换主题，实时查看所有设计令牌在不同主题下的表现。

---

## 🔮 **下一步计划**

### **短期优化 (本周):**
- [ ] 应用新的文本颜色到所有现有页面
- [ ] 验证所有主题下的颜色对比度
- [ ] 优化 Dark Mode 下的文本颜色表现
- [ ] 添加更多字体权重支持

### **中期目标 (本月):**
- [ ] 建立 Figma → Flutter 自动同步流程
- [ ] 创建设计令牌变更的 CI/CD 检查
- [ ] 添加更多设计令牌类型 (动画、边框等)
- [ ] 组件库标准化改造

### **长期愿景 (季度):**
- [ ] 完整的设计系统文档
- [ ] 自动化设计令牌测试
- [ ] 多品牌主题支持
- [ ] 设计令牌版本管理

---

## 📊 **性能影响评估**

### **正面影响:**
- ✅ **编译时优化**: 所有令牌值在编译时确定
- ✅ **内存优化**: 消除重复常量定义
- ✅ **开发效率**: 单一数据源，修改更简单
- ✅ **类型安全**: 保持 Flutter 强类型特性

### **注意事项:**
- ⚠️ **缓存清理**: 修改设计令牌后建议清理 Flutter 缓存
- ⚠️ **主题兼容**: 确保所有自定义主题都支持新的文本颜色
- ⚠️ **测试覆盖**: 在不同设备和主题下测试文本可读性

---

## 🛠️ **故障排除**

### **常见问题:**

#### **Q: 文本颜色没有更新？**
**A:** 
1. 检查组件是否使用了 `DesignTokens.textPrimary` 而不是硬编码颜色
2. 清理 Flutter 缓存: `flutter clean && flutter pub get`
3. 重新启动应用

#### **Q: 字体尺寸显示异常？**
**A:**
1. 确认使用了新的字体尺寸常量 (`fontSizeHeadlineMedium` 等)
2. 检查 `TextTheme` 映射是否正确更新
3. 验证字体文件是否正确加载

#### **Q: 设计令牌可视化页面无法访问？**
**A:**
1. 确认路由已正确配置 (`/design-tokens`)
2. 检查是否需要登录权限
3. 验证应用是否在 debug 模式运行

---

## 📞 **技术支持**

### **文档参考:**
- `README_UIUX.md` - UI/UX 修改边界指南
- `README_RUN.md` - 项目启动和运行指南
- `DesignSystem/README.md` - Figma 集成指南

### **在线工具:**
- Design Tokens 可视化: `http://127.0.0.1:5174/#/design-tokens`
- Figma Tokens Studio 插件
- Material Design 3 颜色工具

---

*最后更新: 2025-01-21*  
*更新人员: AI Assistant*  
*版本: v1.0.0*

