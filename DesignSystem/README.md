# Mystic Tarot JP - Design System

这个目录包含从 Flutter 代码导出的设计令牌，用于 Figma 导入和设计系统管理。

## 文件说明

### `design-tokens.json`
完整的 Design Tokens 文件，符合 Figma Tokens Studio 插件格式。包含：

- **Core Tokens（核心令牌）**: 固定的设计基础值
  - 颜色：边框色、静态文本色
  - 间距：xs(4) → xxl(48)
  - 圆角：xs(4) → lg(24)
  - 字体：Noto Serif JP（标题）、Noto Sans JP（正文）
  - 阴影：卡片阴影
  - 动画：持续时间、缓动曲线

- **Theme Tokens（主题令牌）**: 6个主题变体
  - `theme-moonlight`（ムーンライト）：默认紫色主题
  - `theme-ocean`（オーシャン）：蓝色海洋主题
  - `theme-forest`（フォレスト）：绿色森林暗色主题 + 背景图
  - `theme-nightsky`（ナイトスカイ）：深蓝夜空主题
  - `theme-cloud`（クラウド）：淡蓝云朵主题 + 背景图
  - `theme-clearsky`（クリアスカイ）：明亮天空主题 + 背景图

## 在 Figma 中导入

### 1. 安装插件
在 Figma 中搜索并安装 **"Tokens Studio for Figma"** 插件

### 2. 导入令牌
1. 在 Figma 新建文件或打开现有设计文件
2. 运行 Tokens Studio 插件
3. 选择 **Import** → **Load from JSON**
4. 复制 `design-tokens.json` 的全部内容并粘贴
5. 点击 **Import** 确认

### 3. 应用主题
导入后可以：
- 在插件中切换不同主题（moonlight/ocean/forest 等）
- 查看所有主题下的颜色变化效果
- 使用生成的 Color Styles、Text Styles 设计组件

### 4. 同步更新
当 Flutter 代码中的令牌有变更时：
1. 重新导出生成新的 `design-tokens.json`
2. 在 Figma 中重新导入
3. 所有使用了令牌的设计会自动更新

## 对应关系

| Figma Token | Flutter 代码位置 | 说明 |
|-------------|------------------|------|
| `core.colors.border` | `DesignTokens.borderColor` | 固定边框色 |
| `core.spacing.*` | `DesignTokens.spacing*` | 间距刻度 |
| `core.radius.*` | `DesignTokens.radius*` | 圆角刻度 |
| `theme-*.colors.primary` | `AppThemeData.primaryColor` | 各主题主色 |
| `theme-*.colors.background` | `AppThemeData.backgroundColor` | 各主题背景色 |
| `theme-*.flags.is-dark` | `AppThemeData.isDark` | 是否暗色主题 |

## 注意事项

- **主题背景图**: 3个主题包含背景图片，在 Figma 中需要手动导入对应的图片资源
- **颜色语义**: 每个主题的文本颜色会根据背景亮暗自动调整
- **动画属性**: 导入后可以在 Figma 中应用到 Auto Layout 和 Smart Animate
- **版本同步**: 建议定期重新导出以保持设计与代码的一致性

## 使用建议

1. **建立组件库**: 在 Figma 中使用这些令牌创建 Button、Card、Input 等基础组件
2. **主题验证**: 切换不同主题查看组件在各种配色下的效果
3. **设计交付**: 设计师可以直接在 Figma 中检查间距、字体大小是否符合代码标准
4. **团队协作**: 开发和设计基于同一套令牌，减少沟通成本

---

**生成时间**: 基于 2025-08-21 版本的 Flutter 代码  
**同步状态**: 与 `lib/themes/` 和 `lib/providers/theme_provider.dart` 保持一致

