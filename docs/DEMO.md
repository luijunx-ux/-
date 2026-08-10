# Web Demo 试用说明

## 1. 启动数据库

在项目根目录运行：

```powershell
docker compose up -d postgres
```

## 2. 初始化并启动后端

```powershell
cd backend
.\.venv\Scripts\alembic.exe upgrade head
.\.venv\Scripts\uvicorn.exe app.main:app --reload --host 127.0.0.1 --port 8000
```

## 3. 启动 Web Demo

另开一个 PowerShell 窗口：

```powershell
cd frontend\build\web
python -m http.server 8080 --bind 127.0.0.1
```

浏览器访问 `http://127.0.0.1:8080`。

首次试用请注册一个测试邮箱和不少于 12 个字符的密码。开发环境的邮箱验证及密码重置
令牌只输出到后端日志，不会发送真实邮件。AI 未配置 API Key 时自动使用安全的基础节律建议。

Web Demo 仅用于本地评审。正式移动端安装包仍需安装 Android SDK 后构建。
