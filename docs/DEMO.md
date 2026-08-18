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

如需预置本地审核账号，请在启动后端前设置 `TIANRENLV_DEMO_EMAIL` 和
`TIANRENLV_DEMO_PASSWORD`（密码不少于 12 个字符）；也可以直接注册一个测试邮箱。
开发环境的邮箱验证及密码重置
令牌只输出到后端日志，不会发送真实邮件。AI 未配置 API Key 时自动使用安全的基础节律建议。

Web Demo 仅用于本地评审。

## Android Debug Demo

已生成本地调试包：`frontend/artifacts/tianrenlu-demo-debug.apk`。该包使用 Android Debug
证书签名，仅用于试跑，不得发布到应用商店。构建时 API 地址为电脑 WLAN 地址
`http://10.0.0.16:8000`；手机与电脑必须位于同一局域网，并先以 `0.0.0.0:8000`
启动内存 Demo API。电脑局域网地址变化后需要重新构建 APK。
