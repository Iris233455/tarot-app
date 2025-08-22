"""
重构后的卡牌内容检索系统
实现：场景分类 + 分层字段检索 + Fallback
"""
import json
import re
from typing import Dict, List, Any, Optional, Tuple
from .config import TAROT_JSON, GEMINI_API_KEY, CLASSIFICATION_MODEL
import google.generativeai as genai

# Configure Gemini for classification
genai.configure(api_key=GEMINI_API_KEY)

def load_tarot_json() -> Dict[str, Any]:
    """Load the complete tarot JSON data"""
    with open(TAROT_JSON, 'r', encoding='utf-8') as f:
        return json.load(f)

def classify_scene_regex(question: str) -> str:
    """
    Classify user question into scene categories using simple regex.
    Returns: career|love|money|interperson|other
    """
    question_lower = question.lower()
    

    # Quick intent pre-checks (prioritize interpersonal intent phrases)
    # If question explicitly talks about relationship distance/communication/conflict, treat as interperson
    interperson_intent = r"距離を置く|距離を取る|距離|関係|人間関係|コミュニケーション|信頼|不信|不仲|仲直り|衝突|摩擦|噂|チームワーク|協力|境界|ボーダー|線引き|付き合い|人付き合い"
    if re.search(interperson_intent, question_lower):
        return "interperson"

    # Career patterns
    career_patterns = [
        r'仕事|job|work|career|職|転職|昇進|昇格|キャリア|会社|上司|同僚|業務|プロジェクト|スキル|能力',
        r'business|office|professional|employment|workplace'
    ]
    
    # Love patterns  
    love_patterns = [
        r'恋愛|love|恋|彼氏|彼女|結婚|marriage|partner|relationship|デート|告白|復縁|別れ|片思い',
        r'romantic|dating|boyfriend|girlfriend|spouse|husband|wife'
    ]
    
    # Money patterns
    money_patterns = [
        r'お金|money|金銭|財政|投資|investment|貯金|saving|収入|給料|salary|副業|ビジネス|経済',
        r'financial|income|profit|budget|loan|debt|wealth|rich'
    ]
    
    # Interpersonal patterns
    interperson_patterns = [
        r'人間関係|友達|friend|family|家族|親|子|兄弟|姉妹|neighbor|隣人|コミュニティ|social|人付き合い|コミュニケーション|信頼|不信|衝突|摩擦|噂',
        r'relationship|friendship|親友|同級生|classmate|teammate|coworker|colleague'
    ]
    
    # Check patterns in order (prefer interpersonal over career once intents handled)
    for patterns in love_patterns:
        if re.search(patterns, question_lower):
            return "love"
            
    for patterns in money_patterns:
        if re.search(patterns, question_lower):
            return "money"
            
    for patterns in interperson_patterns:
        if re.search(patterns, question_lower):
            return "interperson"

    for patterns in career_patterns:
        if re.search(patterns, question_lower):
            return "career"
    
    return "other"

def classify_scene_llm(question: str) -> str:
    """
    Classify user question using Gemini LLM.
    Returns: career|love|money|interperson|other
    """
    if not question.strip():
        return "other"
    
    classification_prompt = f"""質問を以下の5つのカテゴリのいずれかに分類してください：

カテゴリ：
- career: 仕事、キャリア、職場に関する質問
- love: 恋愛、結婚、パートナーシップに関する質問  
- money: お金、投資、財政に関する質問
- interperson: 人間関係、友人、家族に関する質問
- other: 上記以外の質問

質問: 「{question}」

回答は必ずcareer, love, money, interperson, otherのうち1つだけを返してください。"""

    try:
        model = genai.GenerativeModel(CLASSIFICATION_MODEL)
        response = model.generate_content(
            classification_prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.1,
                max_output_tokens=10,
                candidate_count=1,
            )
        )
        
        result = response.text.strip().lower()
        
        # Validate result
        valid_categories = {"career", "love", "money", "interperson", "other"}
        if result in valid_categories:
            return result
        else:
            # Fallback to regex if LLM gives invalid result
            return classify_scene_regex(question)
            
    except Exception as e:
        # Fallback to regex on error
        print(f"LLM classification failed: {e}")
        return classify_scene_regex(question)

def classify_scene(question: str) -> str:
    """
    Hybrid classification: regex -> LLM.
    - Run regex first for speed/robustness
    - Then run LLM; if結果有效且与regex不同，则以LLM为准
    - 任一失败时，使用另一个结果作为回退
    Returns: career|love|money|interperson|other
    """
    try:
        regex_result = classify_scene_regex(question or "")
    except Exception:
        regex_result = "other"

    try:
        llm_result = classify_scene_llm(question or "")
    except Exception:
        llm_result = "other"

    valid = {"career", "love", "money", "interperson", "other"}

    # If LLM produced a valid label, prefer it when different (conflict -> LLM wins)
    if llm_result in valid:
        # If regex invalid or different, return LLM
        if regex_result not in valid or llm_result != regex_result:
            return llm_result
        # Same -> either is fine
        return llm_result

    # LLM invalid -> fall back to regex
    return regex_result if regex_result in valid else "other"

def classify_scene_debug(question: str) -> Dict[str, str]:
    """Return regex/llm/final labels for debugging classification."""
    try:
        regex_result = classify_scene_regex(question or "")
    except Exception:
        regex_result = "other"

    try:
        llm_result = classify_scene_llm(question or "")
    except Exception:
        llm_result = "other"

    final = classify_scene(question or "")
    return {"regex": regex_result, "llm": llm_result, "final": final}

def get_card_fields(card_name: str, orientation: str, scene: str, reading_type: str = "general") -> Dict[str, str]:
    """
    Get card fields according to priority order based on scene and reading type.
    
    Args:
        card_name: Name of the card
        orientation: "upright" or "reversed"
        scene: Scene category from classify_scene()
        reading_type: "daily", "one", "two", "three"
        
    Returns:
        Dictionary with field keys and their content
    """
    data = load_tarot_json()
    
    # Find the card
    target_card = None
    for arcana_key in ["major_arcana", "minor_arcana"]:
        if arcana_key in data:
            for card in data[arcana_key]:
                # Try both name formats
                card_name_jp = card.get("name_jp") or card.get("name")
                if card_name_jp == card_name:
                    target_card = card
                    break
            if target_card:
                break
    
    if not target_card:
        return {"error": f"カード「{card_name}」が見つかりませんでした。"}
    
    fields = {}
    
    # Define field priority based on retrieval strategy
    # 1. Core scene-specific fields (only for main 4 scenes)
    if scene in ["career", "love", "money", "interperson"]:
        scene_meaning_key = f"theme_{scene}_{orientation}"
        scene_kw_key = f"theme_{scene}_{orientation}_keywords"
        
        if scene_meaning_key in target_card:
            fields["scene_meaning"] = target_card[scene_meaning_key]
        if scene_kw_key in target_card:
            fields["scene_keywords"] = target_card[scene_kw_key]
    
    # 2. General meaning (always applicable)
    meaning_key = f"meaning_{orientation}"
    if meaning_key in target_card:
        fields["general_meaning"] = target_card[meaning_key]
        
    # 3. General keywords
    kw_key = f"keywords_{orientation}"
    if kw_key in target_card:
        kw_value = target_card[kw_key]
        if isinstance(kw_value, list):
            fields["general_keywords"] = "、".join(kw_value)
        else:
            fields["general_keywords"] = str(kw_value)
    
    # 4. Special fields for specific reading types
    if reading_type == "three":
        # Past/Present/Future field
        ppf_key = f"message_past_present_future_{orientation}"
        if ppf_key in target_card:
            fields["ppf_message"] = target_card[ppf_key]
    
    elif reading_type == "daily":
        # Emotion/Consciousness field
        emotion_key = f"message_emotion_consciousness_{orientation}"
        if emotion_key in target_card:
            fields["emotion_message"] = target_card[emotion_key]
    
    return fields

def fallback_meaning(card_name: str, orientation: str) -> str:
    """
    Get fallback meaning when core fields are missing.
    Returns first sentence (≤40 chars) of meaning_{orientation}.
    """
    data = load_tarot_json()
    
    # Find the card
    target_card = None
    for arcana_key in ["major_arcana", "minor_arcana"]:
        if arcana_key in data:
            for card in data[arcana_key]:
                card_name_jp = card.get("name_jp") or card.get("name")
                if card_name_jp == card_name:
                    target_card = card
                    break
            if target_card:
                break
    
    if not target_card:
        return f"カード「{card_name}」の情報が見つかりません。"
    
    meaning_key = f"meaning_{orientation}"
    if meaning_key in target_card:
        full_meaning = target_card[meaning_key]
        # Extract first sentence or first 40 characters
        sentences = re.split(r'[。．！!？?]', full_meaning)
        first_sentence = sentences[0].strip() if sentences else full_meaning
        if len(first_sentence) > 40:
            first_sentence = first_sentence[:40] + "..."
        return first_sentence
    
    return f"「{card_name}」({orientation})の基本的な意味が見つかりません。"

# Legacy function for backward compatibility (deprecated)
def get_card_content_direct(card_name: str, orientation: str, category: str = "general") -> List[Dict[str, Any]]:
    """
    DEPRECATED: Use get_card_fields() instead.
    Legacy compatibility function.
    """
    scene = "other" if category == "general" else category
    fields = get_card_fields(card_name, orientation, scene)
    
    if "error" in fields:
        return [{"text": fields["error"], "card_name": card_name, "orientation": orientation}]
    
    results = []
    for key, value in fields.items():
        if value and value.strip():
            results.append({
                "text": value,
                "card_name": card_name,
                "orientation": orientation,
                "context_type": key
            })
    
    # If no content found, use fallback
    if not results:
        fallback_text = fallback_meaning(card_name, orientation)
        results.append({
            "text": fallback_text,
            "card_name": card_name,
            "orientation": orientation,
            "context_type": "fallback"
        })
    
    return results