# 订阅功能设置指南

## 概述

本应用已实现订阅功能的基础框架，包括UI界面和模拟支付流程。目前为测试环境，不会产生实际费用。

## 当前功能状态

### ✅ 已实现功能

1. **订阅UI界面**
   - 设置页面显示订阅状态
   - 升级按钮和管理界面
   - 详细的订阅购买对话框

2. **模拟订阅流程**
   - 模拟购买（2秒延迟）
   - 模拟30天订阅期
   - 订阅状态管理和持久化

3. **订阅用户特权**
   - 跳过广告直接解读
   - 无限次数解读
   - 优先体验

### 🚧 预留接口（需要开发者账号）

真实支付功能预留在 `SubscriptionService` 中，包括：
- iOS StoreKit 集成
- Android Google Play Billing 集成
- 服务器端收据验证

## 测试方法

### 1. 模拟订阅测试

```bash
# 运行应用
flutter run

# 测试流程：
# 1. 进入设置页 (マイページ)
# 2. 点击 "プレミアムにアップグレード"
# 3. 选择 "今すぐ購読" (模拟购买)
# 4. 测试解读是否跳过广告
```

### 2. 订阅状态验证

- **订阅前**: 1/2/3卡解读需要观看广告
- **订阅后**: 直接进入解读，无广告
- **到期提醒**: 显示剩余天数

### 3. 订阅管理测试

- **管理界面**: 查看到期时间、取消订阅
- **购买恢复**: 测试跨设备恢复功能

## 开发者账号配置

### iOS 配置 (需要 Apple Developer Account $99/年)

1. **App Store Connect 配置**
   ```
   1. 登录 App Store Connect
   2. 选择应用 → 功能 → App内购买项目
   3. 创建订阅组和订阅产品:
      - 产品ID: premium_monthly
      - 价格: ¥1,000/月
      - 订阅时长: 1个月
   ```

2. **沙盒测试账号**
   ```
   App Store Connect → 用户与访问 → 沙盒测试者
   创建测试账号用于沙盒购买
   ```

3. **代码更新**
   ```dart
   // lib/services/subscription_service.dart
   // 替换测试ID为真实产品ID
   static const String _productId = 'premium_monthly';
   ```

### Android 配置 (需要 Google Play Console $25一次性)

1. **Google Play Console 配置**
   ```
   1. 登录 Play Console
   2. 应用 → 订阅 → 创建订阅
      - 产品ID: premium_monthly  
      - 价格: ¥1,000/月
      - 订阅周期: 1个月
   ```

2. **许可证测试**
   ```
   设置 → 许可证测试
   添加测试账号Gmail地址
   ```

3. **代码更新**
   ```dart
   // 同iOS，使用相同产品ID
   static const String _productId = 'premium_monthly';
   ```

## 生产环境部署

### 1. 服务器端收据验证

```dart
// 实现服务器端验证API
POST /api/verify-receipt
{
  "platform": "ios|android",
  "receipt_data": "base64_receipt",
  "user_id": "user_uuid"
}
```

### 2. 真实支付集成

```dart
// lib/services/subscription_service.dart 中的预留方法
static Future<void> _initializeRealPayment() async {
  // 初始化 InAppPurchase
  final bool available = await InAppPurchase.instance.isAvailable();
  if (!available) return;
  
  // 监听购买流
  InAppPurchase.instance.purchaseStream.listen(_handlePurchaseUpdate);
}
```

### 3. 配置生产广告单元ID

```dart
// lib/services/subscription_service.dart
// 替换测试ID为生产ID
static String get _rewardedAdUnitId {
  if (kDebugMode) {
    return 'test_ad_unit_id';
  } else {
    return 'YOUR_PRODUCTION_AD_UNIT_ID'; // ← 替换这里
  }
}
```

## 沙盒测试环境

### iOS 沙盒特点
- 订阅周期大幅缩短：1个月 → 5分钟
- 自动续订6次后停止
- 使用沙盒测试账号

### Android 沙盒特点  
- 订阅周期可配置缩短
- 测试账号免费购买
- 可模拟各种订阅状态

### 测试检查清单

- [ ] 购买流程完整性
- [ ] 订阅状态同步
- [ ] 到期后功能限制
- [ ] 取消订阅处理
- [ ] 跨设备购买恢复
- [ ] 网络异常处理

## 费用估算

### 开发成本
- Apple Developer: $99/年
- Google Play Console: $25一次性
- 服务器验证API: 根据使用量

### 运营成本
- App Store 手续费: 30% (年收入$100万以下为15%)
- Google Play 手续费: 30% (年收入$100万以下为15%)
- 服务器成本: 验证API调用费用

## 注意事项

1. **隐私合规**: 订阅需要明确的隐私条款和用户同意
2. **退款政策**: 需要清晰的退款和取消政策
3. **区域定价**: 不同国家地区的定价策略
4. **免费试用**: 可考虑提供免费试用期
5. **家庭共享**: iOS支持家庭订阅共享

## 问题排查

### 常见问题
1. **沙盒购买失败**: 检查测试账号和产品配置
2. **收据验证失败**: 确认服务器端验证逻辑
3. **订阅状态不同步**: 检查购买流监听器
4. **跨设备不生效**: 确认购买恢复逻辑

### 调试日志
订阅服务包含详细的 `debugPrint` 日志，可通过控制台查看完整流程。

---

**📱 当前状态**: 完整的测试环境，准备接入真实支付
**🚀 下一步**: 申请开发者账号，配置真实产品ID
