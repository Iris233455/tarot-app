#!/bin/bash

# Google Sign In 自动配置脚本
# 用法: ./setup_google_signin.sh

echo "🔧 Google Sign In 配置脚本"
echo "============================="

# 检查GoogleService-Info.plist是否存在
if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "❌ 错误：找不到 ios/Runner/GoogleService-Info.plist"
    echo "📋 请先完成以下步骤："
    echo "   1. 访问 Google Cloud Console"
    echo "   2. 创建iOS OAuth客户端ID (Bundle ID: com.bendang.tarot.dev)"
    echo "   3. 下载 GoogleService-Info.plist"
    echo "   4. 将文件放到 ios/Runner/ 目录"
    echo "   5. 重新运行此脚本"
    exit 1
fi

echo "✅ 找到 GoogleService-Info.plist"

# 提取REVERSED_CLIENT_ID和CLIENT_ID
REVERSED_CLIENT_ID=$(grep -A1 "REVERSED_CLIENT_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
CLIENT_ID=$(grep -A1 "CLIENT_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | head -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')

if [ -z "$REVERSED_CLIENT_ID" ]; then
    echo "❌ 错误：无法从GoogleService-Info.plist中提取REVERSED_CLIENT_ID"
    exit 1
fi

if [ -z "$CLIENT_ID" ]; then
    echo "❌ 错误：无法从GoogleService-Info.plist中提取CLIENT_ID"
    exit 1
fi

echo "✅ 提取到REVERSED_CLIENT_ID: $REVERSED_CLIENT_ID"
echo "✅ 提取到CLIENT_ID: $CLIENT_ID"

# 更新iOS Info.plist
echo "🔧 更新iOS Info.plist..."
sed -i '' "s/PLACEHOLDER_FOR_REVERSED_CLIENT_ID/$REVERSED_CLIENT_ID/g" ios/Runner/Info.plist

# 检查并添加GIDClientID到iOS Info.plist
if ! grep -q "GIDClientID" ios/Runner/Info.plist; then
    echo "🔧 添加GIDClientID到iOS Info.plist..."
    sed -i '' "/<key>CFBundleURLTypes<\/key>/i\\
	<!-- Google Sign In Client ID -->\\
	<key>GIDClientID</key>\\
	<string>$CLIENT_ID</string>\\
	" ios/Runner/Info.plist
fi

# 更新macOS Info.plist  
echo "🔧 更新macOS Info.plist..."
sed -i '' "s/PLACEHOLDER_FOR_REVERSED_CLIENT_ID/$REVERSED_CLIENT_ID/g" macos/Runner/Info.plist

# 检查并添加GIDClientID到macOS Info.plist
if ! grep -q "GIDClientID" macos/Runner/Info.plist; then
    echo "🔧 添加GIDClientID到macOS Info.plist..."
    sed -i '' "/<key>CFBundleURLTypes<\/key>/i\\
	<!-- Google Sign In Client ID -->\\
	<key>GIDClientID</key>\\
	<string>$CLIENT_ID</string>\\
	" macos/Runner/Info.plist
fi

# 复制配置文件到macOS（如果需要）
if [ ! -f "macos/Runner/GoogleService-Info.plist" ]; then
    echo "📋 复制GoogleService-Info.plist到macOS..."
    cp ios/Runner/GoogleService-Info.plist macos/Runner/
fi

echo ""
echo "🎉 Google Sign In 配置完成！"
echo "============================="
echo "✅ iOS URL Scheme: $REVERSED_CLIENT_ID"
echo "✅ macOS URL Scheme: $REVERSED_CLIENT_ID"
echo "✅ 配置文件已同步"
echo ""
echo "🧪 下一步："
echo "   1. 运行 'flutter clean && flutter pub get'"
echo "   2. 重新构建应用：'flutter run -d macos' 或 'flutter run -d ios'"
echo "   3. 测试Google登录功能"
echo ""
echo "💡 如果仍有问题，请检查："
echo "   - Google Cloud Console中的Bundle ID配置"
echo "   - OAuth同意画面设置"
echo "   - 测试用户邮箱列表"
