"""
重构后的塔罗牌AI解读系统
集成：场景分类 + 字段检索 + 模板化Prompt + 输出校验
"""
import re
import json
import logging
from typing import Dict, List, Any, Optional, Tuple
import unicodedata
import difflib
from functools import lru_cache
from datetime import datetime

import google.generativeai as genai

from .config import GEMINI_API_KEY, READING_MODEL, CLASSIFICATION_MODEL
from .card_content import classify_scene, get_card_fields, fallback_meaning
from .prompts import get_system_prompt, get_template_for_reading_type

# Configure Gemini
genai.configure(api_key=GEMINI_API_KEY)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Temperature and token settings
TEMPERATURE_SETTINGS = {
    "daily": 0.4,
    "one": 0.35,
    "two": 0.35,
    "three": 0.35
}

MAX_TOKENS_SETTINGS = {
    "daily": 400,
    "one": 1100,
    "two": 1200,
    "three": 1400
}

def extract_options_from_question(question: str) -> Optional[tuple]:
    """尝试从日文/中日混合提问句中抽取 (option_a, option_b)。
    扩展支持的形式：
    - 「A」(と|か|/|・|、|,|vs|対|or|または|もしくは|あるいは|それとも)「B」
    - A と B どちら/どっち/のどちら/比べて/比較/を選ぶ/が良い/がいい/の方/のほう
    - A か B（か）... / A または B / A もしくは B / A あるいは B / A or B
    - A vs B / A 対 B / A / B（伴随“どちら/どっち”等）
    未能稳定抽取时返回 None。
    """
    if not question:
        return None

    def normalize_text(text: str) -> str:
        # 统一全半角、空白与常见分隔符
        t = unicodedata.normalize('NFKC', text)
        t = t.replace('\u3000', ' ')
        t = re.sub(r'\s+', ' ', t)
        # 统一斜杠与点号分隔
        return t.strip()

    def clean_option(opt: str) -> str:
        # 去除引号/括号与尾部语气、标点
        opt = opt.strip()
        opt = opt.strip('「」『』()（）[]【】{}<>＜＞')
        # 去除常见句首前缀（今天/本日/今は 等）
        opt = re.sub(r'^(今日は|本日は|今は|きょうは|今日はさ|本日はさ)\s*', '', opt)
        # 去除常见尾随短语
        opt = re.sub(r'(の?どちら|どっち|を?選ぶ.*|が良い.*|がいい.*|にする.*|すべき.*|べき.*)$', '', opt)
        opt = re.sub(r'[、,。.?？!！\s]+$', '', opt)
        return opt.strip()

    q = normalize_text(question)

    # 1) 引号包裹的两选项，连接词多样（支持多种引号）
    quote_pairs = [
        ("「", "」"),
        ("『", "』"),
        ("“", "”"),
        ("《", "》"),
        ('"', '"'),
    ]
    for lq, rq in quote_pairs:
        pattern = rf'{re.escape(lq)}([^ {re.escape(rq)}]+){re.escape(rq)}[^ {re.escape(lq + rq)}]*?(?:と|か|/|・|,|、|vs|VS|ＶＳ|対|or|OR|または|もしくは|あるいは|それとも|还是|或者|或|与|和|对)[^ {re.escape(lq + rq)}]*?{re.escape(lq)}([^ {re.escape(rq)}]+){re.escape(rq)}'
        m = re.search(pattern, q)
        if m:
            a, b = clean_option(m.group(1)), clean_option(m.group(2))
            if a and b and a != b:
                return a, b

    # 2) A と B + どちら/どっち 等提示
    m = re.search(r'(.+?)\s*(?:と|,|、|・|/|＆|&|対|vs|VS|与|和|对)\s*(.+?)(?:の?どちら|どっち|比較|比べて|を?選ぶ|が良い|がいい|の方|のほう|哪个更好|哪个好|更好|比较|对比)', q)
    if m:
        a, b = clean_option(m.group(1)), clean_option(m.group(2))
        if a and b and a != b:
            return a, b

    # 3) A か B（か）...
    m = re.search(r'(.+?)\s*(?:か|还是)\s*(.+?)(?:か|[?？。]|の?どちら|どっち|迷って|迷い|悩んで|悩み|哪个|哪一个|哪個|$)', q)
    if m:
        a, b = clean_option(m.group(1)), clean_option(m.group(2))
        if a and b and a != b:
            return a, b

    # 4) A (または|もしくは|あるいは|それとも|or|OR) B
    m = re.search(r'(.+?)\s*(?:または|もしくは|あるいは|それとも|or|OR|或者|或)\s*(.+?)(?:[?？。]|$)', q)
    if m:
        a, b = clean_option(m.group(1)), clean_option(m.group(2))
        if a and b and a != b:
            return a, b

    # 5) A vs/対 B（宽松）
    m = re.search(r'(.+?)\s*(?:vs|VS|ＶＳ|対)\s*(.+)', q)
    if m:
        a, b = clean_option(m.group(1)), clean_option(m.group(2))
        if a and b and a != b:
            return a, b

    # 6) 退一步：若句中恰好出现两段引号内容，则直接作为A/B（支持多种引号）
    quotes = []
    for lq, rq in quote_pairs:
        quotes += re.findall(rf'{re.escape(lq)}([^ {re.escape(rq)}]+){re.escape(rq)}', q)
    if len(quotes) == 2:
        a, b = clean_option(quotes[0]), clean_option(quotes[1])
        if a and b and a != b:
            return a, b

    return None


def _compute_similarity(a: str, b: str) -> float:
    """Return similarity ratio in [0,1] using SequenceMatcher.
    Higher means more similar.
    """
    return difflib.SequenceMatcher(a=a, b=b).ratio()


def score_options(question: str, option_a: str, option_b: str, reasons: Optional[List[str]] = None) -> float:
    """Rule-based confidence scoring for extracted options in [0,1].
    Heuristic scoring that rewards clear separators and quotes and penalizes ambiguity.
    """
    if reasons is None:
        reasons = []

    q = unicodedata.normalize('NFKC', question or '').strip()
    a = (option_a or '').strip()
    b = (option_b or '').strip()

    if not a or not b:
        reasons.append("missing_option")
        return 0.0

    score = 0.0

    # Base: quoted pair
    if (f'「{a}」' in q and f'「{b}」' in q) or (f'"{a}"' in q and f'"{b}"' in q):
        score += 0.40
        reasons.append("quoted_pair")

    # Connectors
    if re.search(r'(?:と|か|/|・|,|、|vs|VS|ＶＳ|対|or|OR|または|もしくは|あるいは|それとも)', q):
        score += 0.20
        reasons.append("has_connector")

    # Comparison hints
    if re.search(r'(?:どちら|どっち|比較|比べて|を?選ぶ|が良い|がいい|の方|のほう)', q):
        score += 0.20
        reasons.append("has_compare_hint")

    # Length sanity
    len_a = len(a)
    len_b = len(b)
    if 2 <= len_a <= 20 and 2 <= len_b <= 20:
        score += 0.10
        reasons.append("length_ok")
    else:
        reasons.append("length_bad")
        score -= 0.20

    # Length ratio sanity
    ratio = (max(len_a, len_b) / max(1, min(len_a, len_b)))
    if 0.5 <= (min(len_a, len_b) / max(1, max(len_a, len_b))) <= 1.0 and ratio <= 2.0:
        score += 0.10
        reasons.append("length_balance_ok")

    # Similarity penalty
    sim = _compute_similarity(a, b)
    if sim >= 0.6 or a in b or b in a:
        score -= 0.30
        reasons.append("too_similar")
    elif sim < 0.3:
        score += 0.10
        reasons.append("similarity_ok")

    # Pronoun/ambiguous words penalty
    ambiguous_words = [
        "これ", "それ", "あれ", "どれ", "どちら", "どっち", "こっち", "あっち",
        "こちら", "あちら", "どれか", "どっちか"
    ]
    if any(w in a for w in ambiguous_words) or any(w in b for w in ambiguous_words):
        score -= 0.40  # 强化惩罚，确保低置信从而触发确认
        reasons.append("ambiguous_pronoun")

    # Extra separators penalty
    if re.search(r'(?:,|、|/|・).+(?:,|、|/|・)', a) or re.search(r'(?:,|、|/|・).+(?:,|、|/|・)', b):
        score -= 0.20
        reasons.append("nested_separators")

    # Clamp
    score = max(0.0, min(1.0, score))
    return score


def llm_extract_options_flash(question: str) -> Dict[str, Any]:
    """Use a fast LLM (CLASSIFICATION_MODEL) to extract options as JSON.
    Returns dict: {option_a, option_b, confidence, reason}
    """
    json_example = '{"option_a":"","option_b":"","confidence":0.0,"reason":"","language":"ja"}'
    prompt = (
        "次の日本語の質問文から、二択の選択肢AとBを抽出してください。\n"
        "必ず次のJSONのみで返答してください（追加の文章は禁止）：\n"
        + json_example + "\n"
        "規則：option_a/bは短い名詞フレーズ（2-20字）に整形、不要語や句読点を除去。confidenceは[0,1]。\n"
        f"質問: {question}"
    )
    try:
        from .config import CLASSIFICATION_MODEL
        model = genai.GenerativeModel(CLASSIFICATION_MODEL)
        resp = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.1,
                max_output_tokens=60,
                candidate_count=1,
            )
        )
        text = (resp.text or '').strip()
        # Extract JSON
        import json
        m = re.search(r"\{[\s\S]*\}", text)
        if m:
            data = json.loads(m.group(0))
            a = data.get('option_a', '').strip()
            b = data.get('option_b', '').strip()
            conf = float(data.get('confidence', 0.0)) if str(data.get('confidence', '')).strip() != '' else 0.0
            reason = str(data.get('reason', ''))
            return {
                'option_a': a,
                'option_b': b,
                'confidence': max(0.0, min(1.0, conf)),
                'reason': reason or 'llm'
            }
    except Exception as e:
        logger.warning(f"LLM option extraction failed: {e}")
    return {'option_a': '', 'option_b': '', 'confidence': 0.0, 'reason': 'llm_failed'}


def extract_options_with_confidence(question: str) -> Dict[str, Any]:
    """Hybrid extraction: rules first, then LLM fallback when uncertain.
    Returns: {
      option_a, option_b, confidence, method, reasons: List[str], needs_confirmation: bool
    }
    """
    reasons: List[str] = []
    rule_res = extract_options_from_question(question or '')
    if rule_res:
        a, b = rule_res
        conf = score_options(question, a, b, reasons)
        if conf >= 0.70:
            return {
                'option_a': a,
                'option_b': b,
                'confidence': conf,
                'method': 'rule',
                'reasons': reasons,
                'needs_confirmation': False,
            }
        # Medium confidence → call LLM
        if conf >= 0.40:
            reasons.append('rule_medium_conf')
            llm = llm_extract_options_flash(question)
            final_a = llm['option_a'] or a
            final_b = llm['option_b'] or b
            # Merge confidence: prefer higher; if disagree, dampen
            disagree = (final_a != a) or (final_b != b)
            final_conf = max(conf, llm.get('confidence', 0.0)) * (0.9 if disagree else 1.0)
            needs = final_conf < 0.60
            return {
                'option_a': final_a,
                'option_b': final_b,
                'confidence': round(final_conf, 2),
                'method': 'llm' if disagree else 'rule',
                'reasons': reasons + [llm.get('reason', 'llm')],
                'needs_confirmation': needs,
            }
        # Low confidence → suggest confirmation (optionally could call LLM, but we skip)
        reasons.append('rule_low_conf')
        return {
            'option_a': a,
            'option_b': b,
            'confidence': round(conf, 2),
            'method': 'rule',
            'reasons': reasons,
            'needs_confirmation': True,
        }

    # No rule extraction → try LLM straight away
    reasons.append('no_rule_match')
    llm = llm_extract_options_flash(question)
    a = llm.get('option_a', '')
    b = llm.get('option_b', '')
    conf = llm.get('confidence', 0.0)
    needs = not (a and b) or conf < 0.60
    return {
        'option_a': a,
        'option_b': b,
        'confidence': round(float(conf or 0.0), 2),
        'method': 'llm',
        'reasons': reasons + [llm.get('reason', 'llm')],
        'needs_confirmation': needs,
    }

def load_fewshot_examples(reading_type: str) -> List[Dict[str, str]]:
    """
    Load few-shot examples for the given reading type.
    Returns empty list if file doesn't exist or is empty.
    """
    try:
        from pathlib import Path
        fewshot_path = Path(__file__).parent / "fewshot.json"
        with open(fewshot_path, "r", encoding="utf-8") as f:
            fewshot_data = json.load(f)
            return fewshot_data.get(reading_type, [])
    except (FileNotFoundError, json.JSONDecodeError):
        logger.warning(f"Few-shot examples not found for {reading_type}")
        return []

def build_fewshot_section(examples: List[Dict[str, str]]) -> str:
    """Build few-shot examples section for prompt"""
    if not examples:
        return ""
    
    fewshot_text = "\n\n### 参考例\n"
    for i, example in enumerate(examples, 1):
        fewshot_text += f"\n**例{i}:**\n"
        fewshot_text += f"質問: {example.get('question', '')}\n"
        fewshot_text += f"回答: {example.get('answer', '')}\n"
    
    return fewshot_text

def validate_output(text: str, reading_type: str) -> bool:
    """
    Validate output by checking required section headers.
    Returns True if all expected sections are present.
    """
    expected_sections = {
        "daily": ["📖", "🌟", "💖"],
        "one": ["🃏", "💡", "🌙"],
        "two": ["🅰️", "🅱️", "⚖️", "💭"],
        "three": ["⏳", "🕰️", "🔮", "💡", "🌙"]
    }
    
    required_emojis = expected_sections.get(reading_type, [])
    
    for emoji in required_emojis:
        if emoji not in text:
            logger.warning(f"Missing section {emoji} in {reading_type} reading output")
            return False
    
    return True

def build_user_prompt(reading_type: str, cards: List[Dict], question: str = "", user_data: Dict = None) -> str:
    """
    Build user prompt based on reading type and card data.
    """
    template = get_template_for_reading_type(reading_type)
    scene = classify_scene(question) if question else "other"
    scene_label = {
        "career": "仕事/キャリア",
        "love": "恋愛",
        "money": "お金/財政",
        "interperson": "人間関係",
        "other": "一般"
    }.get(scene, "一般")
    
    user_data = user_data or {}
    # Build a lightweight profile context block used across templates
    profile_name = (user_data.get("name") or user_data.get("openid") or user_data.get("user_id") or "").strip()
    profile_birthday = (user_data.get("birthday") or user_data.get("birth_date") or "").strip()
    profile_job = (user_data.get("job") or user_data.get("occupation") or "").strip()
    profile_relationship = (user_data.get("relationship") or user_data.get("relationship_status") or "").strip()
    profile_zodiac = (user_data.get("zodiac") or "").strip()

    def zodiac_from_birthday(date_str: str) -> str:
        try:
            # 支持 YYYY-MM-DD 或 YYYY/MM/DD
            ds = date_str.replace('/', '-')
            d = datetime.strptime(ds, "%Y-%m-%d")
            m, day = d.month, d.day
        except Exception:
            return ""
        # 西洋占星座区间（日本語表記）
        ranges = [
            ((3,21),(4,19),"牡羊座"),
            ((4,20),(5,20),"牡牛座"),
            ((5,21),(6,21),"双子座"),
            ((6,22),(7,22),"蟹座"),
            ((7,23),(8,22),"獅子座"),
            ((8,23),(9,22),"乙女座"),
            ((9,23),(10,23),"天秤座"),
            ((10,24),(11,22),"蠍座"),
            ((11,23),(12,21),"射手座"),
            ((12,22),(12,31),"山羊座"),
            ((1,1),(1,19),"山羊座"),
            ((1,20),(2,18),"水瓶座"),
            ((2,19),(3,20),"魚座"),
        ]
        for (sm, sd), (em, ed), name in ranges:
            if (m == sm and day >= sd) or (m == em and day <= ed) or (sm < m < em) or (sm > em and (m > sm or m < em)):
                return name
        return ""

    # prefer provided zodiac, fallback to birthday-derived zodiac
    computed_zodiac = profile_zodiac or (zodiac_from_birthday(profile_birthday) if profile_birthday else "")
    profile_lines = []
    if profile_name:
        profile_lines.append(f"U1: 名前 = {profile_name}")
    if profile_birthday:
        profile_lines.append(f"U2: 誕生日 = {profile_birthday}")
    if profile_job:
        profile_lines.append(f"U3: 職業 = {profile_job}")
    if profile_relationship:
        profile_lines.append(f"U4: 関係性 = {profile_relationship}")
    if computed_zodiac:
        profile_lines.append(f"U5: 星座 = {computed_zodiac}")
    profile_block = ("\n### ユーザープロファイル\n" + "\n".join(profile_lines) + "\n") if profile_lines else ""
    
    if reading_type == "daily":
        # Daily reading - single card
        card = cards[0]
        card_name = card["name"]
        orientation = card["orientation"]
        
        fields = get_card_fields(card_name, orientation, scene, "daily")
        
        # Handle missing fields with fallback
        meaning = fields.get("general_meaning") or fallback_meaning(card_name, orientation)
        keywords = fields.get("general_keywords", "直感、洞察")
        emotion = fields.get("emotion_message", "内なる声に耳を傾ける時")
        
        # Generate display name
        display_name = (user_data.get("name") or 
                       user_data.get("openid") or 
                       user_data.get("user_id") or 
                       user_data.get("email", "").split("@")[0] if user_data.get("email") else 
                       "あなた")
        
        if not display_name or display_name == "ユーザー":
            display_name = "あなた"
        else:
            display_name = f"{display_name}"
        
        prompt = template.format(
            scene_label=scene_label,
            meaning=meaning,
            keywords=keywords,
            emotion=emotion,
            display_name=display_name
        ) + profile_block
        
    elif reading_type == "one":
        # One card reading
        card = cards[0]
        card_name = card["name"]
        orientation = card["orientation"]
        
        fields = get_card_fields(card_name, orientation, scene, "one")
        
        scene_meaning = fields.get("scene_meaning", "")
        scene_keywords = fields.get("scene_keywords", "")
        general_meaning = fields.get("general_meaning") or fallback_meaning(card_name, orientation)
        general_keywords = fields.get("general_keywords", "直感、洞察")
        
        prompt = template.format(
            scene_label=scene_label,
            scene_meaning=scene_meaning,
            scene_keywords=scene_keywords,
            general_meaning=general_meaning,
            general_keywords=general_keywords,
            question=question,
            card_name=card_name,
            orientation=orientation
        ) + profile_block
        
    elif reading_type == "two":
        # Two cards reading
        card_a, card_b = cards[0], cards[1]
        
        option_a = user_data.get("option_a", "選択肢A")
        option_b = user_data.get("option_b", "選択肢B")
        
        # Use the original question for classification, with option context if available
        full_context = f"{question} {option_a} {option_b}" if question and option_a and option_b else question
        scene = classify_scene(full_context) if full_context else "other"
        scene_label = {
            "career": "仕事/キャリア",
            "love": "恋愛",
            "money": "お金/財政",
            "interperson": "人間関係",
            "other": "一般"
        }.get(scene, "一般")
        
        fields_a = get_card_fields(card_a["name"], card_a["orientation"], scene, "two")
        fields_b = get_card_fields(card_b["name"], card_b["orientation"], scene, "two")
        
        prompt = template.format(
            scene_label=scene_label,
            question=question or f"{option_a} と {option_b} どちらが良い？",
            option_a=option_a,
            option_b=option_b,
            card_name_a=card_a["name"],
            orientation_a=card_a["orientation"],
            scene_meaning_a=fields_a.get("scene_meaning", ""),
            scene_keywords_a=fields_a.get("scene_keywords", ""),
            general_meaning_a=fields_a.get("general_meaning") or fallback_meaning(card_a["name"], card_a["orientation"]),
            card_name_b=card_b["name"],
            orientation_b=card_b["orientation"],
            scene_meaning_b=fields_b.get("scene_meaning", ""),
            scene_keywords_b=fields_b.get("scene_keywords", ""),
            general_meaning_b=fields_b.get("general_meaning") or fallback_meaning(card_b["name"], card_b["orientation"])
        ) + profile_block
        
    elif reading_type == "three":
        # Three cards reading
        card_past, card_now, card_future = cards[0], cards[1], cards[2]
        
        fields_past = get_card_fields(card_past["name"], card_past["orientation"], scene, "three")
        fields_now = get_card_fields(card_now["name"], card_now["orientation"], scene, "three")  
        fields_future = get_card_fields(card_future["name"], card_future["orientation"], scene, "three")
        
        prompt = template.format(
            scene_label=scene_label,
            question=question,
            card_name_past=card_past["name"],
            orientation_past=card_past["orientation"],
            scene_meaning_past=fields_past.get("scene_meaning", ""),
            ppf_past=fields_past.get("ppf_message", "過去の経験からの学び"),
            card_name_now=card_now["name"],
            orientation_now=card_now["orientation"],
            scene_meaning_now=fields_now.get("scene_meaning", ""),
            ppf_now=fields_now.get("ppf_message", "現在取り組むべき課題"),
            card_name_future=card_future["name"],
            orientation_future=card_future["orientation"],
            scene_meaning_future=fields_future.get("scene_meaning", ""),
            ppf_future=fields_future.get("ppf_message", "未来への可能性")
        ) + profile_block
    
    else:
        raise ValueError(f"Unsupported reading type: {reading_type}")
    
    # Add few-shot examples if available
    fewshot_examples = load_fewshot_examples(reading_type)
    fewshot_section = build_fewshot_section(fewshot_examples)
    
    return prompt + fewshot_section

def call_gemini_with_retry(system_prompt: str, user_prompt: str, reading_type: str, max_retries: int = 2) -> str:
    """
    Call Gemini API with retry logic for validation failures.
    """
    temperature = TEMPERATURE_SETTINGS.get(reading_type, 0.3)
    max_tokens = MAX_TOKENS_SETTINGS.get(reading_type, 800)
    
    for attempt in range(max_retries + 1):
        try:
            # Adjust temperature for retries
            current_temp = temperature + (0.1 * attempt)
            
            model = genai.GenerativeModel(READING_MODEL)
            
            # Combine system and user prompts
            full_prompt = f"{system_prompt}\n\n{user_prompt}"
            
            # Configure safety settings for tarot content
            safety_settings = [
                {
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_HATE_SPEECH", 
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE"
                }
            ]
            
            response = model.generate_content(
                full_prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=current_temp,
                    max_output_tokens=max_tokens,
                    candidate_count=1,
                ),
                safety_settings=safety_settings
            )
            
            # Check if response has valid content
            if not response.candidates or not response.candidates[0].content:
                raise Exception(f"Gemini returned empty response. Finish reason: {response.candidates[0].finish_reason if response.candidates else 'Unknown'}")
            
            result = response.text
            
            # Remove citation markers and references
            result = re.sub(r'《[A-Z]\d+》', '', result)  # Remove bracketed references
            result = re.sub(r'\b[A-Z]\d+\b', '', result)  # Remove standalone references like "A4"
            result = re.sub(r'[A-Z]\d+の', '', result)  # Remove "A4の" patterns
            result = re.sub(r'、[A-Z]\d+、?', '、', result)  # Remove comma-separated references
            
            # Validate output
            if validate_output(result, reading_type):
                logger.info(f"Gemini API call successful for {reading_type} (attempt {attempt + 1})")
                return result
            else:
                logger.warning(f"Output validation failed for {reading_type} (attempt {attempt + 1})")
                if attempt == max_retries:
                    # Return result even if validation fails on final attempt
                    return result
                continue
                
        except Exception as e:
            logger.error(f"Gemini API call failed (attempt {attempt + 1}): {str(e)}")
            if attempt == max_retries:
                raise e
            continue
    
    raise Exception(f"Failed to get valid response after {max_retries + 1} attempts")

def tarot_reading(reading_type: str, cards: List[Dict], question: str = "", user_data: Dict = None) -> str:
    """
    Main function for generating tarot readings.
    
    Args:
        reading_type: Type of reading ("daily", "one", "two", "three")
        cards: List of card dictionaries with "name" and "orientation"
        question: User's question (optional for daily)
        user_data: User information including name, options for two-card reading
        
    Returns:
        Generated reading in Japanese
    """
    try:
        logger.info(f"Starting {reading_type} reading with {len(cards)} cards")
        
        # Build prompts
        system_prompt = get_system_prompt()
        user_prompt = build_user_prompt(reading_type, cards, question, user_data)
        
        # Call Gemini with retry
        result = call_gemini_with_retry(system_prompt, user_prompt, reading_type)
        
        # Replace generic placeholders in two-cards with concrete option names
        if reading_type == "two":
            option_a = (user_data or {}).get('option_a') or ''
            option_b = (user_data or {}).get('option_b') or ''
            if option_a:
                result = re.sub(r'\b(選択肢A|オプションA|Option\s*A)\b', option_a, result)
            if option_b:
                result = re.sub(r'\b(選択肢B|オプションB|Option\s*B)\b', option_b, result)

        # Clean up extra spaces and punctuation while preserving line breaks
        result = re.sub(r'[ \t]+', ' ', result)  # Multiple spaces/tabs to single space (preserve newlines)
        result = re.sub(r'、\s*、', '、', result)  # Double commas to single
        result = re.sub(r'^\s*、', '', result, flags=re.MULTILINE)  # Leading commas
        result = re.sub(r'\n\s*\n\s*\n+', '\n\n', result)  # Multiple empty lines to double newline
        result = result.strip()
        
        logger.info(f"Successfully generated {reading_type} reading")
        return result
        
    except Exception as e:
        logger.error(f"Error in tarot_reading: {str(e)}")
        raise e