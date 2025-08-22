#!/usr/bin/env python3
"""
修复 const TextStyle 与 DynamicTokens 冲突的问题
"""

import os
import re

def fix_const_issues_in_file(file_path, dry_run=True):
    """修复单个文件中的 const 问题"""
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # 修复模式1: const TextStyle(fontWeight: DynamicTokens.xxx)
        pattern1 = r'const\s+TextStyle\s*\(\s*([^)]*DynamicTokens\.fontWeight[^)]*)\)'
        matches1 = re.findall(pattern1, content)
        if matches1:
            content = re.sub(pattern1, r'TextStyle(\1)', content)
            changes_made.append(f"  移除 const TextStyle 中的 const ({len(matches1)}处)")
        
        # 修复模式2: const Text(..., style: TextStyle(fontWeight: DynamicTokens.xxx))
        pattern2 = r'const\s+Text\s*\(\s*([^,]+),\s*style:\s*TextStyle\s*\(\s*([^)]*DynamicTokens\.fontWeight[^)]*)\)'
        matches2 = re.findall(pattern2, content)
        if matches2:
            content = re.sub(pattern2, r'Text(\1, style: TextStyle(\2))', content)
            changes_made.append(f"  移除 const Text 中的 const ({len(matches2)}处)")
        
        # 修复模式3: style: const TextStyle(fontWeight: DynamicTokens.xxx)
        pattern3 = r'style:\s*const\s+TextStyle\s*\(\s*([^)]*DynamicTokens\.fontWeight[^)]*)\)'
        matches3 = re.findall(pattern3, content)
        if matches3:
            content = re.sub(pattern3, r'style: TextStyle(\1)', content)
            changes_made.append(f"  移除 style: const TextStyle 中的 const ({len(matches3)}处)")
        
        # 修复模式4: child: const Text(..., style: TextStyle(fontWeight: DynamicTokens.xxx))
        pattern4 = r'child:\s*const\s+Text\s*\(\s*([^,]+),\s*style:\s*TextStyle\s*\(\s*([^)]*DynamicTokens\.fontWeight[^)]*)\)'
        matches4 = re.findall(pattern4, content)
        if matches4:
            content = re.sub(pattern4, r'child: Text(\1, style: TextStyle(\2))', content)
            changes_made.append(f"  移除 child: const Text 中的 const ({len(matches4)}处)")
        
        # 如果有变化
        if changes_made:
            if not dry_run:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"✅ 已修复: {file_path}")
            else:
                print(f"📝 将修复: {file_path}")
            
            for change in changes_made:
                print(change)
            print()
            
            return len(changes_made)
        
        return 0
        
    except Exception as e:
        print(f"❌ 处理文件时出错 {file_path}: {e}")
        return 0

def batch_fix_const_issues(lib_path, dry_run=True):
    """批量修复 const 问题"""
    
    total_files_processed = 0
    total_changes = 0
    
    print("=" * 80)
    print("🔧 修复 const TextStyle 与 DynamicTokens 冲突")
    print("=" * 80)
    print(f"模式: {'🔍 预览模式 (不实际修改)' if dry_run else '✏️  实际修改模式'}")
    print()
    
    # 遍历所有 Dart 文件
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                
                changes = fix_const_issues_in_file(file_path, dry_run)
                if changes > 0:
                    total_files_processed += 1
                    total_changes += changes
    
    print("=" * 80)
    print("📊 修复统计")
    print("=" * 80)
    print(f"处理文件数: {total_files_processed}")
    print(f"总修复数: {total_changes}")
    print()
    
    if dry_run:
        print("🔍 这是预览模式，没有实际修改文件")
        print("💡 要执行实际修复，请运行: python3 fix_const_font_weights.py --apply")
    else:
        print("✅ 所有修复已完成！")
        print("🧪 建议运行测试确保应用正常工作")
    
    print("=" * 80)
    
    return total_files_processed, total_changes

if __name__ == "__main__":
    import sys
    
    lib_path = "lib"
    
    if not os.path.exists(lib_path):
        print(f"❌ 错误: 找不到 {lib_path} 目录")
        exit(1)
    
    # 检查命令行参数
    dry_run = "--apply" not in sys.argv
    
    if dry_run:
        print("🔍 开始预览 const 修复...")
    else:
        print("✏️  开始执行 const 修复...")
    
    total_files, total_changes = batch_fix_const_issues(lib_path, dry_run)
    
    print(f"\n🎯 完成! 处理了 {total_files} 个文件，共 {total_changes} 处修复")
