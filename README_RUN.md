# 本地测试启动指南（AI 后端 + Flutter 客户端）

本文档说明如何在本地启动 AI 后端，然后启动 Flutter 客户端（以 macOS 为例）。
cd /Users/toshunmei/Desktop/Tarot/Tarot_Card_App/ai_backend
source .venv/bin/activate
uvicorn app.api:app --reload --host 0.0.0.0 --port 8000
## 一、启动 AI 后端
1) 进入后端目录并启用虚拟环境：
```bash
cd /Users/toshunmei/Desktop/Tarot/Tarot_Card_App/ai_backend
source .venv/bin/activate
```

2) 运行服务（默认 0.0.0.0:8000）：
```bash
uvicorn app.api:app --reload --host 0.0.0.0 --port 8000
```

> 首次运行如未安装依赖，请先执行：`pip install -r requirements.txt`

## 二、启动 Flutter 客户端（macOS）
在另一个终端执行：
```bash
cd /Users/toshunmei/Desktop/Tarot/Tarot_Card_App
flutter run -d macos | cat
```

- 运行期间：按 `r` 热重载、`R` 热重启、`q` 退出。
- 默认前端会访问本机后端（http://localhost:8000）。如后端端口/主机变更，请在前端配置中同步调整。

## 常见问题
- 无法连接后端：确认 AI 后端终端已在运行且端口正确。
- 首次后端报错：在激活虚拟环境后执行 `pip install -r requirements.txt` 再重试。
- 依赖变更：前端运行前可执行 `flutter pub get`。

 
