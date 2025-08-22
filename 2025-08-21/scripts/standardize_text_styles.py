#!/usr/bin/env python3
"""
批量替换硬编码的文字样式为设计令牌
"""

import os
import re
from pathlib import Path

def replace_hardcoded_styles(file_path):
    """替换文件中的硬编码样式"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 替换字体大小
    replacements = [
        # 字体大小
        (r'fontSize:\s*24', 'fontSize: dynamicTokens.fontSizeHeadlineMedium'),
        (r'fontSize:\s*20', 'fontSize: dynamicTokens.fontSizeTitleLarge'),
        (r'fontSize:\s*18', 'fontSize: dynamicTokens.fontSizeTitleMedium'),
        (r'fontSize:\s*16', 'fontSize: dynamicTokens.fontSizeBodyLarge'),
        (r'fontSize:\s*14', 'fontSize: dynamicTokens.fontSizeBodyMedium'),
        (r'fontSize:\s*12', 'fontSize: dynamicTokens.fontSizeBodySmall'),
        (r'fontSize:\s*11', 'fontSize: dynamicTokens.fontSizeCaption'),
        (r'fontSize:\s*10', 'fontSize: dynamicTokens.fontSizeCaption'),
        
        # 颜色替换
        (r'Colors\.white', 'dynamicTokens.textWhite'),
        (r'Colors\.white\.withOpacity\(0\.9\)', 'dynamicTokens.textWhite70'),
        (r'Colors\.white\.withOpacity\(0\.8\)', 'dynamicTokens.textWhite70'),
        (r'Colors\.white\.withOpacity\(0\.7\)', 'dynamicTokens.textWhite54'),
        (r'Colors\.white54', 'dynamicTokens.textWhite54'),
        (r'Colors\.white70', 'dynamicTokens.textWhite70'),
        (r'Colors\.grey', 'dynamicTokens.textTertiary'),
        (r'Colors\.grey\[600\]', 'dynamicTokens.textGrey600'),
        (r'Colors\.grey\[500\]', 'dynamicTokens.textGrey500'),
        (r'Colors\.black87', 'dynamicTokens.textBlack87'),
        (r'Colors\.redAccent', 'dynamicTokens.textError'),
        (r'Colors\.green', 'dynamicTokens.textSuccess'),
        (r'Colors\.red', 'dynamicTokens.textError'),
        (r'Colors\.purple', 'dynamicTokens.primaryColor'),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    # 如果内容有变化，写回文件
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ 已更新: {file_path}")
        return True
    else:
        print(f"⏭️  无需更新: {file_path}")
        return False

def main():
    """主函数"""
    # 项目根目录
    project_root = Path("/Users/toshunmei/Desktop/Tarot/Tarot_Card_App/2025-08-21")
    
    # 需要处理的Dart文件
    dart_files = [
        "lib/screens/home/home_screen.dart",
        "lib/screens/history_screen.dart",
        "lib/screens/card_detail_screen.dart",
        "lib/screens/reading/result_page.dart",
        "lib/screens/reading/format_select_page.dart",
        "lib/screens/reading/question_input_page.dart",
        "lib/screens/deck_selection/deck_selection_screen.dart",
        "lib/screens/gallery/gallery_screen.dart",
        "lib/screens/reading_detail_screen.dart",
        "lib/screens/auth/auth_screen.dart",
    ]
    
    updated_count = 0
    
    for file_path in dart_files:
        full_path = project_root / file_path
        if full_path.exists():
            if replace_hardcoded_styles(full_path):
                updated_count += 1
        else:
            print(f"❌ 文件不存在: {file_path}")
    
    print(f"\n🎉 完成！共更新了 {updated_count} 个文件")

if __name__ == "__main__":
    main()
