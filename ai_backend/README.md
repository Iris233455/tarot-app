# Tarot AI Backend

该目录包含一个基于 FastAPI + OpenAI + FAISS 的轻量级塔罗解读后端，可与 Flutter 前端应用对接。

## 功能
1. 使用 `tarot_books_processed_clean.json` 构建向量库（RAG）。
2. 暴露 `/reading` API，根据阅读模式 (daily / one / two / three) + 抽到的牌 + 用户资料 + 问题，返回中文解读。
3. Prompt 已加入检索上下文，减少 LLM 幻觉。

## 快速开始
```bash
# 1. 进入 backend 目录
cd ai_backend

# 2. 安装依赖（推荐虚拟环境）
pip install -r requirements.txt

# 3. 设置环境变量
export OPENAI_API_KEY=sk-xxxxxxx

# 4. 首次运行需构建向量库，约 1~2min 视网络而定
python -c "from app.vector_store import create_vector_store; create_vector_store()"

# 5. 启动服务
uvicorn app.api:app --reload --host 0.0.0.0 --port 8000
```

## 接口示例
```bash
curl -X POST http://localhost:8000/reading \
     -H "Content-Type: application/json" \
     -d '{
        "reading_type": "one",
        "question": "最近感到工作压力很大，该怎么应对？",
        "cards": [ { "name": "女教皇", "orientation": "upright" } ],
        "user": { "name": "Yuki", "birthday": "1995-10-05", "job": "Engineer", "relationship": "Single" }
     }'
```

## Flutter 对接
在 `lib/services` 新建 `ai_service.dart`，向本地或云端部署的 API 发请求。
```dart
class AIService {
  static const _baseUrl = 'http://127.0.0.1:8000';

  static Future<String> reading({
    required String readingType,
    required List<Map<String, String>> cards,
    String question = '',
    Map<String, String>? user,
  }) async {
    final body = {
      'reading_type': readingType,
      'question': question,
      'cards': cards,
      'user': user ?? {},
    };
    final res = await http.post(Uri.parse('$_baseUrl/reading'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['result'];
    } else {
      throw Exception(res.body);
    }
  }
}
```

## 目录结构
```
ai_backend/
  ├── app/
  │   ├── __init__.py
  │   ├── api.py            # FastAPI 入口
  │   ├── config.py         # 常量 & 路径
  │   ├── data_loader.py    # JSON -> 文档块
  │   ├── vector_store.py   # 向量库构建 & 检索
  │   └── reader.py         # Prompt + LLM 调用
  ├── requirements.txt
  └── README.md
```

> 后续你可以根据业务需要扩展 `reader.py` 的 prompt 或增加多语言支持。
