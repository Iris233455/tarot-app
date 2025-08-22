import os
from pathlib import Path
from dotenv import load_dotenv

# ====== Load .env file ======
ROOT_DIR = Path(__file__).resolve().parent.parent  # ai_backend/
# 优先加载 ai_backend/.env；使用 override=True 以覆盖空值或已存在但无效的环境变量
load_dotenv(ROOT_DIR / ".env", override=True)

# ====== Paths ======
ASSETS_DIR = ROOT_DIR.parent / "assets" / "data"
TAROT_JSON = ASSETS_DIR / "tarot_books_contents.json"

# ====== Gemini API ======
# 兼容两种变量名：GEMINI_API_KEY 与 GOOGLE_API_KEY（google-generativeai 官方推荐）
GEMINI_API_KEY = (
    os.getenv("GEMINI_API_KEY")
    or os.getenv("GOOGLE_API_KEY")
)
CLASSIFICATION_MODEL = "gemini-1.5-flash"  # 分类模型  
READING_MODEL = "gemini-1.5-pro"  # 正文生成模型

# ====== Retrieval ======
CHUNK_SIZE = 512  # max tokens per chunk when splitting long fields
