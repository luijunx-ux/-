# 天人律 AI 生命节律 Agent APP：项目状态总览

更新时间：2026-08-10
当前版本：`0.3.0-alpha.1`
当前分支：`main`
远程仓库：`git@github.com:luijunx-ux/-.git`
远程同步提交：`f81e2f3`

## 一、项目目标

开发一套 AI 生命节律移动应用。用户输入出生年月日、时间和地点后，系统建立个人生命
档案，计算星座与五运六气，并结合规则、知识库和大模型生成每日生活建议。

所有星座、五运六气和每日节律内容均定位为文化性、自我观察式的一般生活参考，不构成
医疗诊断、治疗建议、命运判断或重大决策依据。

## 二、技术架构

- 客户端：Flutter，包含 Android、iOS 和 Web 平台工程。
- API：Python 3.12+、FastAPI、Pydantic。
- 数据库：PostgreSQL、SQLAlchemy Async、Alembic。
- AI：OpenAI Responses API、Agent、Markdown RAG、安全策略及确定性降级。
- 地理服务：OpenStreetMap Nominatim 显式搜索、服务端限速和缓存。
- 时区：`timezonefinder` 离线解析 IANA 时区。
- 认证：Argon2id、JWT Access Token、轮换式 Refresh Token。
- 移动端安全存储：`flutter_secure_storage`。
- 质量工具：pytest、Ruff、mypy、Flutter Test。

## 三、已经完成的产品能力

### 3.1 账户与隐私

- 邮箱注册和登录，密码至少 12 个字符。
- Argon2id 密码哈希，服务端不保存明文密码。
- JWT Access Token，包含 issuer、audience、exp、nbf 和 jti 校验。
- Refresh Token 仅以 SHA-256 哈希入库，默认有效期 30 天。
- Refresh Token 每次续期自动轮换，旧令牌立即失效。
- Flutter 启动恢复会话，运行期间请求遇到 401 自动续期并重试一次。
- 并发 401 合并为一次刷新，避免 Refresh Token 被重复消费。
- 退出登录撤销当前 Refresh Token。
- Access Token 使用 `sid` 绑定当前 Refresh Token 会话。
- 账户页展示有效登录会话，并支持一键退出其他设备。
- 永久注销账户并级联删除生命档案、建议历史和会话。
- 注册、登录及账户邮件请求采用 Redis 原子滑动窗口分布式限流，Redis 键仅包含邮箱 SHA-256 哈希。
- 开发环境允许在 Redis 不可用时降级到内存限流；非开发环境必须配置 Redis，服务不可用时认证请求返回 503。
- 登录成功和失败事件入库，审计记录只包含邮箱哈希。

### 3.2 邮箱验证与密码重置

- 邮箱验证和密码重置使用有时限、单次消费的一次性令牌。
- 数据库只保存一次性令牌哈希。
- 请求接口使用统一模糊响应，不泄露邮箱是否注册。
- 开发环境通过安全日志输出操作链接。
- 可配置 SMTP+STARTTLS 邮件适配器。
- Flutter Web 可从邮件 URL 自动完成邮箱验证。
- Flutter Web 可从邮件 URL进入新密码设置页面。
- 原生 Android/iOS Universal Link、App Link 尚未配置。

### 3.3 生命档案

- 输入出生日期、时间、地点、经纬度和 IANA 时区。
- 明确点击后搜索地点，不执行逐字自动补全。
- 自动填写标准地点名称、经纬度和时区。
- 计算太阳星座、元素和模式。
- 计算五运六气中运、太过/不及、司天和在泉。
- 算法版本为 `calendar_year_v1`，节气边界提供复核提示。
- 生命档案保存到 PostgreSQL，并严格按用户隔离。
- 自定义档案名称、编辑出生资料、查看和删除档案。
- 每个用户最多一个默认档案。
- 首个档案自动成为默认档案。
- 删除默认档案时自动选择最近档案接替。
- 编辑出生资料时自动清理该档案的旧建议缓存。

### 3.4 每日 AI 建议

- 今日节律首页自动展示默认档案。
- 支持选择日期生成每日建议。
- Markdown 知识库 RAG 检索。
- OpenAI Responses API 严格 JSON Schema 输出。
- 默认模型配置为 `gpt-5.6-terra`，`store: false`。
- 不向模型发送精确出生时间、地址、坐标、邮箱等个人信息。
- 已登录用户使用 HMAC 伪匿名安全标识。
- AI 不可用时自动返回确定性基础建议。
- AI 输出未通过安全检查时自动使用安全降级建议。
- 同一用户、档案和日期只保存一份建议，重复查看不重复调用模型。
- 建议历史、缓存状态、“有帮助/没帮助”反馈和连续查看天数。
- 审计只记录随机请求 ID、模型、模式、Token 数量、知识来源数量和安全结果，
  不记录出生数据或建议正文。

### 3.5 Demo

- Flutter Web release 构建已成功。
- 正式 Web Demo 默认调用 `http://127.0.0.1:8000`。
- 提供不依赖 PostgreSQL 的一次性内存 Demo API：`app.demo_main:app`。
- 内存 Demo 预设账号：用户名 `admin`；密码只用于本地演示，详见 Demo 运行说明。
- 内存 Demo 关闭后清空用户、档案和建议数据。
- Demo 说明位于 `docs/DEMO.md`。
- Android SDK 36、NDK、CMake 与 Gradle 工具链已安装，Debug Demo APK 已成功生成并通过签名及清单校验。
- 当前 Debug APK 使用包名 `com.tianrenlu.tianrenlu`，最低 Android 7.0（API 24），目标 API 36。

## 四、主要 API

### 4.1 认证

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `GET /api/v1/auth/sessions`
- `DELETE /api/v1/auth/sessions/others`
- `POST /api/v1/auth/email-verification/request`
- `POST /api/v1/auth/email-verification/confirm`
- `POST /api/v1/auth/password-reset/request`
- `POST /api/v1/auth/password-reset/confirm`
- `GET /api/v1/users/me`
- `DELETE /api/v1/users/me`

### 4.2 档案、地点与建议

- `GET /api/v1/locations/search?q=...`
- `POST /api/v1/profiles/generate`：匿名临时计算。
- `POST /api/v1/profiles`：创建并保存档案。
- `GET /api/v1/profiles`：读取当前用户档案列表。
- `GET /api/v1/profiles/{id}`：读取档案详情。
- `PUT /api/v1/profiles/{id}`：编辑档案及默认状态。
- `DELETE /api/v1/profiles/{id}`：删除档案。
- `POST /api/v1/advice/daily`：兼容匿名建议。
- `POST /api/v1/profiles/{id}/advice/daily`：生成或读取缓存建议。
- `GET /api/v1/advice/history`
- `PUT /api/v1/advice/{id}/feedback`
- `GET /api/v1/advice/stats`

## 五、数据库迁移

当前 Alembic head：`20260810_0006`。

1. `20260809_0001`：创建生命档案表。
2. `20260810_0002`：创建用户表及档案所有权。
3. `20260810_0003`：档案名称和默认档案。
4. `20260810_0004`：每日建议历史、缓存和反馈。
5. `20260810_0005`：Refresh Token 会话。
6. `20260810_0006`：账户一次性令牌和安全事件。

迁移链已通过离线 SQL 生成验证。实际部署前执行：

```powershell
cd backend
.\.venv\Scripts\alembic.exe upgrade head
```

## 六、环境配置

使用根目录 `.env.example` 创建本地 `.env`，不要提交真实凭据。

关键配置包括：

- `DATABASE_URL`
- `JWT_SECRET_KEY`
- `SAFETY_IDENTIFIER_SECRET`
- `REFRESH_TOKEN_DAYS`
- `AI_ENABLED`
- `LLM_API_KEY`
- `LLM_MODEL`
- `APP_PUBLIC_URL`
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_FROM_EMAIL`
- `SMTP_USE_TLS`

非开发环境若继续使用示例 JWT 或安全标识密钥，后端会拒绝启动。

## 七、本地运行

### 7.1 正式后端

需要 PostgreSQL。Docker Compose 文件位于 `infrastructure/docker/docker-compose.yml`。

```powershell
docker compose -f infrastructure\docker\docker-compose.yml up -d postgres
cd backend
.\.venv\Scripts\alembic.exe upgrade head
.\.venv\Scripts\uvicorn.exe app.main:app --host 127.0.0.1 --port 8000
```

### 7.2 内存 Demo 后端

无需 Docker 或 PostgreSQL：

```powershell
cd backend
.\.venv\Scripts\uvicorn.exe app.demo_main:app --host 127.0.0.1 --port 8000
```

### 7.3 Web Demo

```powershell
cd frontend
flutter build web --release `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 `
  --dart-define=DEMO_MODE=true
cd build\web
python -m http.server 8080 --bind 127.0.0.1
```

浏览器访问 `http://127.0.0.1:8080`。

## 八、最近验证结果

- 后端 pytest：38 项通过。
- Ruff：通过。
- mypy strict：通过。
- Flutter Test：15 项通过。
- Flutter Web release：构建成功。
- Alembic 六段迁移链：通过。
- Web Demo 和内存 Demo API：本地 HTTP 200。
- GitHub SSH 认证和推送：成功。

Flutter `analyze` 在包含中文字符的 Windows 工作区路径中会触发 Analysis Server LSP JSON
解析异常；Flutter 测试和 Web release 编译均可正常完成。Web 构建使用当前 JavaScript 后端，
`flutter_secure_storage_web` 暂不兼容 Wasm 构建。

## 九、Git 状态

- Git 提交者：`liujun <luijunx@gmail.com>`。
- 当前远程：`git@github.com:luijunx-ux/-.git`。
- 当前分支：`main`。
- 最近已推送提交：`f81e2f3 feat: add distributed authentication rate limiting`。
- 当前项目专用 SSH 私钥只保存在用户 `.ssh` 目录，未进入仓库。
- 本地 Demo 压缩包和构建目录已被 `.gitignore` 排除。

## 十、尚未完成与建议顺序

1. 配置真实 SMTP 账户并完成测试邮件投递。
2. 配置正式 Web 域名、HTTPS 和 `APP_PUBLIC_URL`。
3. 为 Android/iOS 配置 Universal Link、App Link 和密码重置原生页面唤起。
4. 为 Redis 配置生产级认证、TLS、监控告警与容量基线。
5. 为会话列表增加设备名称、系统版本、最近活动时间和异常登录提醒。
6. 配置正式应用图标、名称、Release Keystore，并生成可发布的签名 APK/AAB。
7. 补充 UI 自动化、真实 PostgreSQL 集成测试和并发缓存测试。
8. 自托管地理编码服务或采购具备 SLA 的服务。
9. 配置正式 OpenAI API Key，执行安全评测集和成本/延迟基准。
10. 配置 CI/CD、Sentry/OTel、备份恢复和生产密钥管理。

## 十一、安全注意事项

- 不要将 `.env`、SMTP 密码、OpenAI API Key 或 SSH 私钥提交到 Git。
- Demo 账号只允许用于本机内存演示服务，不得用于生产环境。
- 生产环境必须使用 HTTPS、强随机独立密钥和受控邮件供应商。
- 生产邮件日志不得包含一次性令牌或完整操作链接。
- 需要对 AI、认证、地理服务和建议历史配置监控、保留周期与删除策略。
