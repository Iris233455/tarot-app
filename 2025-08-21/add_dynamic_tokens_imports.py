#!/usr/bin/env python3
"""
为使用了 DynamicTokens 但缺少导入的文件添加导入语句
"""

import os
import re

def add_import_to_file(file_path, import_statement):
    """为文件添加导入语句"""
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 检查是否已经有这个导入
        if import_statement.strip() in content:
            return False, "已存在导入"
        
        # 检查是否使用了 DynamicTokens
        if 'DynamicTokens.' not in content:
            return False, "未使用 DynamicTokens"
        
        lines = content.split('\n')
        
        # 找到合适的位置插入导入语句
        # 通常在其他 import 语句之后，在第一个非 import 行之前
        import_insert_index = 0
        
        for i, line in enumerate(lines):
            if line.strip().startswith('import '):
                import_insert_index = i + 1
            elif line.strip() and not line.strip().startswith('//') and not line.strip().startswith('import '):
                break
        
        # 插入导入语句
        lines.insert(import_insert_index, import_statement)
        
        # 写回文件
        new_content = '\n'.join(lines)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        return True, "导入已添加"
        
    except Exception as e:
        return False, f"错误: {e}"

def batch_add_imports():
    """批量添加导入语句"""
    
    import_statement = "import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';"
    
    # 需要添加导入的文件列表
    files_to_update = [
        'lib/core/theme/app_theme.dart',
        'lib/screens/draw_cards_screen.dart', 
        'lib/screens/card_detail_screen.dart',
        'lib/screens/dev/design_tokens_screen.dart',
        'lib/screens/redemption/redemption_screen.dart',
        'lib/themes/theme.dart',
        'lib/widgets/tarot_card_widget.dart',
        'lib/widgets/loading_overlay.dart'
    ]
    
    print("=" * 80)
    print("🔧 添加 DynamicTokens 导入语句")
    print("=" * 80)
    
    success_count = 0
    
    for file_path in files_to_update:
        if os.path.exists(file_path):
            success, message = add_import_to_file(file_path, import_statement)
            
            if success:
                print(f"✅ {file_path}")
                print(f"   {message}")
                success_count += 1
            else:
                print(f"⏭️  {file_path}")
                print(f"   {message}")
        else:
            print(f"❌ {file_path}")
            print(f"   文件不存在")
        
        print()
    
    print("=" * 80)
    print(f"📊 完成! 成功添加导入到 {success_count}/{len(files_to_update)} 个文件")
    print("=" * 80)

if __name__ == "__main__":
    batch_add_imports()
