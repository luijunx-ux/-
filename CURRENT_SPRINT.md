# CURRENT SPRINT：全链路、安全、部署与 Alpha

版本目标：`v0.3.0-alpha-readiness`

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
