#!/usr/bin/env python3
"""
批量替换 Flutter 项目中的硬编码 FontWeight 为 Design Token
"""

import os
import re
from pathlib import Path

def replace_font_weights_in_file(file_path, replacements, dry_run=True):
    """在单个文件中替换字体粗细"""
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()
        
        content = original_content
        changes_made = []
        
        # 执行替换
        for old_pattern, new_token in replacements.items():
            if old_pattern in content:
                # 计算替换次数
                count = content.count(old_pattern)
                content = content.replace(old_pattern, new_token)
                changes_made.append(f"  {old_pattern} → {new_token} ({count}处)")
        
        # 如果有变化
        if changes_made:
            if not dry_run:
                # 实际写入文件
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"✅ 已更新: {file_path}")
            else:
                print(f"📝 将更新: {file_path}")
            
            for change in changes_made:
                print(change)
            print()
            
            return len(changes_made)
        
        return 0
        
    except Exception as e:
        print(f"❌ 处理文件时出错 {file_path}: {e}")
        return 0

def batch_replace_font_weights(lib_path, dry_run=True):
    """批量替换字体粗细"""
    
    # 定义替换映射 - 排除 tokens.dart 中的定义
    replacements = {
        'FontWeight.w300': 'DynamicTokens.fontWeightLight',
        'FontWeight.normal': 'DynamicTokens.fontWeightRegular',
        'FontWeight.w400': 'DynamicTokens.fontWeightRegular', 
        'FontWeight.w500': 'DynamicTokens.fontWeightMedium',
        'FontWeight.w600': 'DynamicTokens.fontWeightSemiBold',
        'FontWeight.bold': 'DynamicTokens.fontWeightBold',
        'FontWeight.w700': 'DynamicTokens.fontWeightBold',
        'FontWeight.w800': 'DynamicTokens.fontWeightExtraBold',
        'FontWeight.w900': 'DynamicTokens.fontWeightBlack',
    }
    
    # 需要排除的文件（Design Token 定义文件）
    excluded_files = {
        'lib/themes/tokens.dart',  # Design Token 定义文件
        'lib/themes/dynamic_tokens.dart',  # Dynamic Token 文件
    }
    
    total_files_processed = 0
    total_changes = 0
    
    print("=" * 80)
    print("🎯 批量替换字体粗细为 Design Token")
    print("=" * 80)
    print(f"模式: {'🔍 预览模式 (不实际修改)' if dry_run else '✏️  实际修改模式'}")
    print()
    
    # 遍历所有 Dart 文件
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, '.')
                
                # 跳过排除的文件
                if rel_path in excluded_files:
                    print(f"⏭️  跳过: {rel_path} (Design Token 定义文件)")
                    continue
                
                changes = replace_font_weights_in_file(file_path, replacements, dry_run)
                if changes > 0:
                    total_files_processed += 1
                    total_changes += changes
    
    print("=" * 80)
    print("📊 替换统计")
    print("=" * 80)
    print(f"处理文件数: {total_files_processed}")
    print(f"总替换数: {total_changes}")
    print()
    
    if dry_run:
        print("🔍 这是预览模式，没有实际修改文件")
        print("💡 要执行实际替换，请运行: python3 replace_font_weights.py --apply")
    else:
        print("✅ 所有替换已完成！")
        print("🧪 建议运行测试确保应用正常工作")
    
    print("=" * 80)
    
    return total_files_processed, total_changes

def check_import_statements(lib_path):
    """检查哪些文件需要添加 DynamicTokens 导入"""
    
    print("\n🔍 检查导入语句...")
    files_need_import = []
    
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, '.')
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # 检查是否使用了 DynamicTokens 但没有导入
                    if 'DynamicTokens.' in content:
                        if 'package:mystic_tarot_jp/themes/dynamic_tokens.dart' not in content:
                            files_need_import.append(rel_path)
                            
                except Exception as e:
                    print(f"❌ 检查文件时出错 {file_path}: {e}")
    
    if files_need_import:
        print(f"\n⚠️  以下 {len(files_need_import)} 个文件可能需要添加 DynamicTokens 导入:")
        for file_path in files_need_import:
            print(f"  📄 {file_path}")
        print("\n💡 建议添加导入语句:")
        print("   import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';")
    else:
        print("✅ 所有文件的导入语句都正确")

if __name__ == "__main__":
    import sys
    
    lib_path = "lib"
    
    if not os.path.exists(lib_path):
        print(f"❌ 错误: 找不到 {lib_path} 目录")
        exit(1)
    
    # 检查命令行参数
    dry_run = "--apply" not in sys.argv
    
    if dry_run:
        print("🔍 开始预览字体粗细替换...")
    else:
        print("✏️  开始执行字体粗细替换...")
    
    total_files, total_changes = batch_replace_font_weights(lib_path, dry_run)
    
    # 检查导入语句
    if not dry_run and total_changes > 0:
        check_import_statements(lib_path)
    
    print(f"\n🎯 完成! 处理了 {total_files} 个文件，共 {total_changes} 处替换")
