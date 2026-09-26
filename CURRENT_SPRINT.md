# CURRENT SPRINT：全链路、安全、部署与 Alpha

版本目标：`v0.3.0-alpha.1`

状态：进行中；Sprint 6 双主题视觉基线已获用户明确审核通过。

## 输入与依赖

- V3 产品、需求与 UI 冻结基线。
- 已通过审核的 Forest Life / Obsidian Life 双主题实现。
- 现有 FastAPI、Flutter、PostgreSQL、Redis、Agent 与 RAG 实现。

## 本 Sprint 范围

1. 建立 GitHub Actions 质量门禁，覆盖后端、Flutter 和密钥泄漏检查。
2. 完成真实 PostgreSQL/Redis 集成验证与迁移验证。
3. 建立结构化日志、错误追踪和最小运行监控基线。
4. 完成生产环境配置校验、容器化与部署说明。
5. 完成 Alpha 安全评测、恢复演练和发布检查清单。

## 非范围

- 不扩展 P1/P2 产品功能。
- 不修改未经专家验证的五运六气知识规则。
- 不让 LLM 参与确定性历法、天文或五运六气计算。
- 不提交生产密钥、真实用户数据或签名构建物。
- 不改变已经视觉审核通过的双主题方向。

## 模块顺序

1. CI 质量门禁与跨平台测试可复现性。
2. PostgreSQL/Redis 全链路集成测试。
3. 可观测性与生产配置验证。
4. 部署、备份恢复和 Alpha 发布门禁。

## 验收标准

- Pull Request 和 `main` 推送自动运行后端 lint、类型检查、测试及 Flutter analyze/test。
- CI 不依赖开发者本机字体或绝对路径，视觉回归测试可复现。
- 集成测试使用临时服务，不访问生产环境或真实用户数据。
- 生产配置缺失或使用模板密钥时快速失败。
- 发布清单明确安全、隐私、回滚和人工审核负责人。

## 回滚策略

- 每个模块独立提交，可单独回滚。
- CI 故障只允许修复流水线，不允许通过删除安全检查或核心测试绕过。
- 部署异常时回滚上一稳定镜像和数据库向后兼容版本；不可逆迁移必须先提供恢复方案。

## 模块 1：CI 质量门禁

状态：实现完成，等待审核与首次 GitHub Actions 运行验证。

- [x] 新增 GitHub Actions 后端和 Flutter 并行检查。
- [x] 新增 Git 历史密钥泄漏检查。
- [x] 将视觉测试字体加载改为跨平台、环境可配置。
- [x] 本地复现后端 lint、类型检查、测试及 Flutter analyze/test。
- [ ] 提交后确认 GitHub Actions 在 Linux Runner 首次运行通过。

## 当前模块：PostgreSQL / Redis 全链路集成测试

状态：实现完成，等待审核与 GitHub Linux Runner 真实服务验证。

- [x] CI 使用临时 PostgreSQL 17 与 Redis 7 服务，不访问生产数据。
- [x] 在测试前执行 Alembic 全量迁移。
- [x] 验证迁移版本、JSONB 持久化、仓储读写与用户删除级联。
- [x] 验证 Redis 限流跨实例共享、达到上限拒绝和标识符哈希保护。
- [ ] 在 GitHub Linux Runner 上完成首次真实服务验证。

## 当前模块：可观测性与生产配置验证

状态：本地实现与验证完成，等待审核及 GitHub Linux Runner 验证。

- [x] API 响应返回 `X-Request-ID`，并支持安全格式的客户端请求标识。
- [x] 输出结构化访问日志，明确排除查询参数、请求体、认证信息和个人敏感数据。
- [x] 提供兼容健康检查、进程存活检查与 PostgreSQL/Redis 就绪检查。
- [x] 生产环境拒绝模板密钥、缺失 Redis 及不可用的共享限流服务。
- [x] 新增日志脱敏、请求标识和依赖状态自动化测试及运维基线文档。
- [ ] 提交后确认 GitHub Linux Runner 全量检查通过。

## 当前模块：部署、备份恢复和 Alpha 发布门禁

状态：本地实现完成，等待审核、容器实际构建和 GitHub Linux Runner 验证。

- [x] 新增非 root FastAPI 生产镜像及 GitHub Actions 镜像构建门禁。
- [x] 新增迁移先行、数据库/缓存隔离和就绪检查驱动的 Alpha 容器编排。
- [x] 扩展生产配置快速失败：数据库模板凭据、HTTPS、SMTP 与 AI 密钥。
- [x] 新增 PostgreSQL 备份、校验、显式确认恢复及迁移重放脚本。
- [x] 明确 Alpha RPO/RTO、恢复演练、回滚流程与四类人工审核负责人。
- [x] 新增安全、隐私、内容、视觉、备份和停止测试的发布门禁清单。
- [x] 完成本机镜像构建、非 root 运行、全量迁移及 PostgreSQL/Redis 就绪检查。
- [x] 使用 PostgreSQL 自定义格式生成备份，并验证 SHA-256 与恢复目录清单。
- [x] 将镜像运行、迁移、健康检查、备份和隔离恢复演练加入 CI 门禁。
- [x] 在纯合成数据环境完成一次实际恢复，约 1 分钟恢复就绪并形成演练记录。
- [x] 新增 Python 依赖漏洞门禁、CycloneDX SBOM 和 Alpha 安全评测基线。
- [x] 新增固定版本的容器高危/严重漏洞扫描门禁，仅在一次性 CI Runner 运行。
- [x] 统一后端、API、Flutter 和容器版本为 `0.3.0-alpha.1` 并加入一致性门禁。
- [x] 移除 Android Release 调试签名，缺少专用签名配置时快速失败并补充密钥模板。
- [ ] 提交后确认 GitHub Linux Runner 全量检查及容器构建通过。
