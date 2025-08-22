import 'package:shared_preferences/shared_preferences.dart';
import 'package:mystic_tarot_jp/services/deck_service.dart';

/// 塔罗牌背面设计管理服务
class CardBackService {
  static const String _selectedBackDesignKey = 'selected_back_design';
  static const String _defaultBackDesign = 'default';
  
  /// 获取当前选中的背面设计类型
  static Future<String> getSelectedBackDesign() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedBackDesignKey) ?? _defaultBackDesign;
  }
  
  /// 设置背面设计类型
  static Future<void> setBackDesign(String designType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedBackDesignKey, designType);
  }
  
  /// 获取当前应该使用的背面图片路径
  static Future<String> getCurrentBackImageUrl() async {
    final selectedDesign = await getSelectedBackDesign();
    
    if (selectedDesign == _defaultBackDesign) {
      // 使用当前套牌的默认背面
      final currentDeck = await DeckService.getCurrentDeck();
      if (currentDeck != null) {
        return currentDeck.defaultBackImageUrl;
      }
              // 如果没有找到当前套牌，使用默认套牌的背面
        final defaultDeck = await DeckService.getDeckById('rider_waite');
        return defaultDeck?.defaultBackImageUrl ?? 'assets/images/tarot/rider_waite/back.jpeg';
    } else {
      // 使用自定义背面设计
      return 'assets/images/back_designs/$selectedDesign';
    }
  }
  
  /// 获取所有可用的背面设计选项
  static List<Map<String, dynamic>> getAvailableBackDesigns() {
    return [
      {'name': 'デフォルト', 'type': 'default', 'description': '現在のデッキの背面'},
      {'name': '月', 'type': 'moon_back.jpg', 'description': '月のデザイン'},
      {'name': '星', 'type': 'star_back.jpg', 'description': '星のデザイン'},
      {'name': '花', 'type': 'flower_back.jpg', 'description': '花のデザイン'},
    ];
  }
  
  /// 检查背面设计是否可用
  static Future<bool> isBackDesignAvailable(String designType) async {
    if (designType == _defaultBackDesign) {
      // 检查当前套牌是否有默认背面
      final currentDeck = await DeckService.getCurrentDeck();
      return currentDeck != null;
    } else {
      // 这里可以添加检查自定义背面文件是否存在的逻辑
      return true; // 暂时返回true
    }
  }
  
  /// 重置为默认背面设计
  static Future<void> resetToDefault() async {
    await setBackDesign(_defaultBackDesign);
  }
}