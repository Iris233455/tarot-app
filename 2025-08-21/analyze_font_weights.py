#!/usr/bin/env python3
"""
分析 Flutter 项目中所有 FontWeight 的使用情况
"""

import os
import re
from collections import defaultdict, Counter

def analyze_font_weights(lib_path):
    """分析字体粗细使用情况"""
    
    # 字体粗细映射
    font_weight_mapping = {
        'FontWeight.w100': 'fontWeightThin (w100)',
        'FontWeight.w200': 'fontWeightExtraLight (w200)', 
        'FontWeight.w300': 'fontWeightLight (w300)',
        'FontWeight.w400': 'fontWeightRegular (w400)',
        'FontWeight.normal': 'fontWeightRegular (w400)',
        'FontWeight.w500': 'fontWeightMedium (w500)',
        'FontWeight.w600': 'fontWeightSemiBold (w600)',
        'FontWeight.w700': 'fontWeightBold (w700)',
        'FontWeight.bold': 'fontWeightBold (w700)',
        'FontWeight.w800': 'fontWeightExtraBold (w800)',
        'FontWeight.w900': 'fontWeightBlack (w900)',
    }
    
    # 统计数据
    file_stats = defaultdict(list)
    weight_counter = Counter()
    usage_contexts = defaultdict(list)
    
    # 遍历所有 Dart 文件
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, lib_path)
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        lines = content.split('\n')
                        
                        # 查找 FontWeight 使用
                        for i, line in enumerate(lines, 1):
                            for pattern in font_weight_mapping.keys():
                                if pattern in line:
                                    weight_counter[pattern] += 1
                                    file_stats[rel_path].append({
                                        'line': i,
                                        'weight': pattern,
                                        'context': line.strip(),
                                        'mapped_token': font_weight_mapping[pattern]
                                    })
                                    
                                    # 分析使用上下文
                                    context_lines = []
                                    start = max(0, i-3)
                                    end = min(len(lines), i+2)
                                    for j in range(start, end):
                                        prefix = ">>> " if j == i-1 else "    "
                                        context_lines.append(f"{prefix}{j+1:3d}: {lines[j]}")
                                    
                                    usage_contexts[pattern].append({
                                        'file': rel_path,
                                        'line': i,
                                        'context': '\n'.join(context_lines)
                                    })
                                    
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")
    
    return file_stats, weight_counter, usage_contexts, font_weight_mapping

def print_analysis_report(file_stats, weight_counter, usage_contexts, font_weight_mapping):
    """打印分析报告"""
    
    print("=" * 80)
    print("🎯 Flutter 项目字体粗细使用情况分析报告")
    print("=" * 80)
    
    # 1. 总体统计
    print("\n📊 1. 总体使用统计")
    print("-" * 40)
    total_usages = sum(weight_counter.values())
    print(f"总计发现 {total_usages} 处字体粗细使用")
    print(f"涉及 {len(file_stats)} 个文件")
    print(f"使用了 {len(weight_counter)} 种不同的字体粗细")
    
    # 2. 字体粗细使用频率
    print("\n📈 2. 字体粗细使用频率排行")
    print("-" * 40)
    for weight, count in weight_counter.most_common():
        mapped = font_weight_mapping.get(weight, weight)
        percentage = (count / total_usages) * 100
        print(f"{weight:20} → {mapped:25} | {count:3d}次 ({percentage:5.1f}%)")
    
    # 3. 文件级别统计
    print("\n📁 3. 各文件使用情况")
    print("-" * 40)
    for file_path, usages in sorted(file_stats.items()):
        print(f"\n📄 {file_path} ({len(usages)}处)")
        for usage in usages:
            print(f"  L{usage['line']:3d}: {usage['weight']:20} → {usage['mapped_token']}")
    
    # 4. 推荐的 Design Token 映射
    print("\n🎨 4. 推荐的 Design Token 标准化映射")
    print("-" * 40)
    print("建议将以下硬编码替换为 Design Token:")
    print()
    
    replacement_map = {
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
    
    for old, new in replacement_map.items():
        if old in weight_counter:
            count = weight_counter[old]
            print(f"{old:20} → {new:35} ({count}处)")
    
    # 5. 高频使用场景分析
    print("\n🔍 5. 主要使用场景分析")
    print("-" * 40)
    
    # 分析最常用的几种字体粗细的使用场景
    top_weights = weight_counter.most_common(5)
    for weight, count in top_weights:
        print(f"\n▶ {weight} ({count}处使用):")
        contexts = usage_contexts[weight][:3]  # 显示前3个使用场景
        for i, ctx in enumerate(contexts, 1):
            print(f"  场景{i}: {ctx['file']}:{ctx['line']}")
            # 只显示关键行
            key_line = [line for line in ctx['context'].split('\n') if '>>>' in line]
            if key_line:
                print(f"         {key_line[0].replace('>>>', '   ')}")
    
    return replacement_map

if __name__ == "__main__":
    lib_path = "lib"
    
    if not os.path.exists(lib_path):
        print(f"错误: 找不到 {lib_path} 目录")
        exit(1)
    
    print("🔍 开始分析字体粗细使用情况...")
    file_stats, weight_counter, usage_contexts, font_weight_mapping = analyze_font_weights(lib_path)
    
    replacement_map = print_analysis_report(file_stats, weight_counter, usage_contexts, font_weight_mapping)
    
    print("\n" + "=" * 80)
    print("✅ 分析完成！")
    print("=" * 80)
