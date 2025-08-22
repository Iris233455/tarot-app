#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
塔罗牌数据合并脚本
将现有的两个数据文件合并为统一的数据架构
"""

import json
import os
from datetime import datetime

def load_json_file(file_path):
    """加载JSON文件"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def clean_keywords(keywords_str):
    """清理关键词字符串，转换为数组"""
    try:
        # 移除多余的引号和括号
        cleaned = keywords_str.strip("[]'\"")
        # 分割关键词
        keywords = [kw.strip().strip("'\"") for kw in cleaned.split(',')]
        return keywords
    except:
        return []

def merge_tarot_data():
    """合并塔罗牌数据"""
    
    # 定义文件路径
    base_path = "assets/data"
    clean_file = os.path.join(base_path, "tarot_books_contents.json")
    
    # 检查文件是否存在
    if not os.path.exists(clean_file):
        print(f"错误：找不到文件 {clean_file}")
        return
    
    # 加载基础数据（使用cat套牌的数据作为基础）
    print("加载基础数据...")
    clean_data = load_json_file(clean_file)
    
    # 创建统一数据结构
    unified_data = {
        "metadata": {
            "version": "1.0",
            "description": "统一塔罗牌数据架构，支持多套牌",
            "created_at": datetime.now().strftime("%Y-%m-%d"),
            "last_updated": datetime.now().strftime("%Y-%m-%d")
        },
        "decks": {
            "rider_waite": {
                "deck_id": "rider_waite",
                "deck_name_jp": "ライダー・ウェイト版",
                "deck_name_en": "Rider-Waite Tarot",
                "deck_description": "最も有名で伝統的なタロットデック",
                "deck_author": "A.E.ウェイト & パメラ・コールマン・スミス",
                "deck_year": "1909",
                "image_path": "rider_waite",
                "file_extension": ".jpeg",
                "back_image": "back.jpeg",
                "is_default": True
            },
            "cat": {
                "deck_id": "cat",
                "deck_name_jp": "猫タロット",
                "deck_name_en": "Cat Tarot",
                "deck_description": "可愛らしい猫をモチーフにしたタロットデック",
                "deck_author": "オリジナル",
                "deck_year": "2024",
                "image_path": "cat",
                "file_extension": ".png",
                "back_image": "back.png",
                "is_default": False
            }
        },
        "cards": {}
    }
    
    # 处理大阿尔卡纳牌
    print("处理大阿尔卡纳牌...")
    if "major_arcana" in clean_data:
        major_cards = []
        for card in clean_data["major_arcana"]:
            # 处理关键词
            keywords_upright = clean_keywords(card.get("keywords_upright", ""))
            keywords_reversed = clean_keywords(card.get("keywords_reversed", ""))
            
            # 创建统一的卡片数据（不包含filename）
            unified_card = {
                "card_id": card["card_id"],
                "name_jp": card["name_jp"],
                "name_en": card["name_en"],
                "base_filename": card["filename"].replace(".png", "").replace(".jpeg", ""),
                "page_number": card.get("page_number", 0),
                "story": card.get("story", ""),
                "meaning_upright": card.get("meaning_upright", ""),
                "meaning_reversed": card.get("meaning_reversed", ""),
                "keywords_upright": keywords_upright,
                "keywords_reversed": keywords_reversed,
                "message_past_present_future_upright": card.get("message_past_present_future_upright", ""),
                "message_past_present_future_reversed": card.get("message_past_present_future_reversed", ""),
                "message_emotion_consciousness_upright": card.get("message_emotion_consciousness_upright", ""),
                "message_emotion_consciousness_reversed": card.get("message_emotion_consciousness_reversed", ""),
                "message_cause_solution_upright": card.get("message_cause_solution_upright", ""),
                "message_cause_solution_reversed": card.get("message_cause_solution_reversed", ""),
                "theme_interpersonal_upright": card.get("theme_interpersonal_upright", ""),
                "theme_interpersonal_reversed": card.get("theme_interpersonal_reversed", "")
            }
            major_cards.append(unified_card)
        
        unified_data["cards"]["major_arcana"] = major_cards
        print(f"处理了 {len(major_cards)} 张大阿尔卡纳牌")
    
    # 处理小阿尔卡纳牌
    print("处理小阿尔卡纳牌...")
    minor_cards = []
    
    # 处理各个花色
    suits = ["wands", "cups", "swords", "pentacles"]
    for suit in suits:
        if suit in clean_data:
            for card in clean_data[suit]:
                keywords_upright = clean_keywords(card.get("keywords_upright", ""))
                keywords_reversed = clean_keywords(card.get("keywords_reversed", ""))
                
                unified_card = {
                    "card_id": card["card_id"],
                    "name_jp": card["name_jp"],
                    "name_en": card["name_en"],
                    "base_filename": card["filename"].replace(".png", "").replace(".jpeg", ""),
                    "suit": suit,
                    "number": card.get("number", 0),
                    "page_number": card.get("page_number", 0),
                    "story": card.get("story", ""),
                    "meaning_upright": card.get("meaning_upright", ""),
                    "meaning_reversed": card.get("meaning_reversed", ""),
                    "keywords_upright": keywords_upright,
                    "keywords_reversed": keywords_reversed,
                    "message_past_present_future_upright": card.get("message_past_present_future_upright", ""),
                    "message_past_present_future_reversed": card.get("message_past_present_future_reversed", ""),
                    "message_emotion_consciousness_upright": card.get("message_emotion_consciousness_upright", ""),
                    "message_emotion_consciousness_reversed": card.get("message_emotion_consciousness_reversed", ""),
                    "message_cause_solution_upright": card.get("message_cause_solution_upright", ""),
                    "message_cause_solution_reversed": card.get("message_cause_solution_reversed", ""),
                    "theme_interpersonal_upright": card.get("theme_interpersonal_upright", ""),
                    "theme_interpersonal_reversed": card.get("theme_interpersonal_reversed", "")
                }
                minor_cards.append(unified_card)
    
    unified_data["cards"]["minor_arcana"] = minor_cards
    print(f"处理了 {len(minor_cards)} 张小阿尔卡纳牌")
    
    # 保存统一数据文件
    output_file = os.path.join(base_path, "unified_tarot_data.json")
    print(f"保存统一数据到 {output_file}...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(unified_data, f, ensure_ascii=False, indent=2)
    
    print("✅ 数据合并完成！")
    print(f"📊 统计信息：")
    print(f"   - 套牌数量：{len(unified_data['decks'])}")
    print(f"   - 大阿尔卡纳：{len(unified_data['cards']['major_arcana'])} 张")
    print(f"   - 小阿尔卡纳：{len(unified_data['cards']['minor_arcana'])} 张")
    print(f"   - 总卡片数：{len(unified_data['cards']['major_arcana']) + len(unified_data['cards']['minor_arcana'])} 张")

if __name__ == "__main__":
    merge_tarot_data()
