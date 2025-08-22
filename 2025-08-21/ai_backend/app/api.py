from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Literal, Optional

from .reader import tarot_reading, extract_options_from_question, extract_options_with_confidence
from .card_content import classify_scene_debug, get_card_fields

app = FastAPI(title="Tarot AI Backend", version="0.1.0")

@app.get("/test")
async def test_config():
    """Test endpoint to check configuration"""
    from .config import GEMINI_API_KEY
    return {
        "api_key_loaded": bool(GEMINI_API_KEY),
        "api_key_preview": GEMINI_API_KEY[:10] + "..." if GEMINI_API_KEY else "NOT_SET",
        "api_provider": "Gemini"
    }

@app.post("/debug/retrieve")
async def debug_retrieve(payload: dict):
    """Debug endpoint: given question, card name(s), orientation(s), and reading_type,
    return classification (regex/llm/final) and retrieved fields used to build prompts.
    Example payload:
    {
      "question": "今日は仕事か家族どっち？",
      "reading_type": "two",
      "cards": [{"name":"愚者","orientation":"upright"},{"name":"魔術師","orientation":"reversed"}]
    }
    """
    try:
        question = str(payload.get("question", ""))
        reading_type = str(payload.get("reading_type", "one"))
        cards = payload.get("cards", []) or []

        scene_info = classify_scene_debug(question)
        scene = scene_info.get("final", "other")

        fields_list = []
        for c in cards:
            name = c.get("name")
            orientation = c.get("orientation", "upright")
            fields = get_card_fields(name, orientation, scene, reading_type)
            fields_list.append({"name": name, "orientation": orientation, "fields": fields})

        return {
            "scene": scene_info,
            "reading_type": reading_type,
            "cards": fields_list,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

ReadingType = Literal["daily", "one", "two", "three"]

class Card(BaseModel):
    name: str = Field(..., description="Card name in JP or EN")
    orientation: Literal["upright", "reversed"] = "upright"

class UserProfile(BaseModel):
    name: Optional[str] = None
    birthday: Optional[str] = None  # YYYY-MM-DD
    job: Optional[str] = None
    relationship: Optional[str] = None
    zodiac: Optional[str] = None  # 例: 牡羊座/Aries

class ReadingRequest(BaseModel):
    reading_type: ReadingType
    question: Optional[str] = ""
    cards: List[Card]
    user: Optional[UserProfile] = UserProfile()
    option_a: Optional[str] = ""  # Two Cards専用：選択肢A
    option_b: Optional[str] = ""  # Two Cards専用：選択肢B
    debug_options: Optional[bool] = False  # 解析メタ情報の返却（開発用）

class ReadingResponse(BaseModel):
    result: str
    options_meta: Optional[dict] = None

@app.post("/reading", response_model=ReadingResponse)
async def reading_endpoint(payload: ReadingRequest):
    try:
        # ユーザー情報にoption_a/option_bを追加
        user_data = payload.user.dict() if payload.user else {}
        if payload.option_a:
            user_data['option_a'] = payload.option_a
        if payload.option_b:
            user_data['option_b'] = payload.option_b
        options_meta = None
        # Auto-extract options with confidence if two-cards and options missing
        if payload.reading_type == "two" and (not user_data.get('option_a') or not user_data.get('option_b')):
            options_meta = extract_options_with_confidence(payload.question or "")
            if options_meta and options_meta.get('option_a') and options_meta.get('option_b'):
                user_data['option_a'] = user_data.get('option_a') or options_meta['option_a']
                user_data['option_b'] = user_data.get('option_b') or options_meta['option_b']
            
        result = tarot_reading(
            reading_type=payload.reading_type,
            question=payload.question or "",
            cards=[c.dict() for c in payload.cards],
            user_data=user_data,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return ReadingResponse(result=result, options_meta=(options_meta if payload.debug_options else None))
