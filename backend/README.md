# Backend

Python FastAPI 服务工程边界。

## 账户与隐私

- 密码使用 Argon2id 哈希，JWT 访问令牌默认有效期为 30 分钟。
- Refresh Token 默认有效期 30 天，仅以 SHA-256 哈希入库；每次刷新都会轮换并使旧令牌失效。
- `POST /api/v1/auth/logout` 会撤销当前 Refresh Token，账户删除会级联撤销全部会话。
- 登录、注册及邮件请求采用滑动窗口限流；登录结果写入仅含邮箱哈希的安全事件表。
- 邮箱验证与密码重置使用有时限、单次消费的一次性令牌，数据库仅保存令牌哈希。
- 开发环境通过专用日志邮件适配器输出令牌；生产部署必须接入真实邮件供应商。
- 持久化生命档案必须通过 Bearer 鉴权，并按用户 ID 隔离查询。
- 删除 `/api/v1/users/me` 会通过 PostgreSQL 外键级联删除该用户的生命档案。
- 非开发环境使用示例 JWT 或安全标识密钥时，应用会拒绝启动。
- 生产上线前仍需实现登录限流、邮箱验证、密码重置和令牌撤销名单。

## 生命档案接口

登录后可使用 `POST /api/v1/profiles` 保存档案、`GET /api/v1/profiles` 获取自己的
档案列表、`GET /api/v1/profiles/{id}` 查看详情，以及
`DELETE /api/v1/profiles/{id}` 删除档案。所有接口按当前用户隔离数据。
`PUT /api/v1/profiles/{id}` 可更新档案名称、出生资料和默认状态；每个用户最多只有一个
默认档案，首个档案会自动成为默认档案。

## 每日建议记录

`POST /api/v1/profiles/{id}/advice/daily` 按档案和日期生成并缓存建议，同一天重复请求
不会再次调用模型。登录用户可通过 `/api/v1/advice/history` 查看历史、通过
`/api/v1/advice/{id}/feedback` 提交反馈，并通过 `/api/v1/advice/stats` 获取连续查看天数。
