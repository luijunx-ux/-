# Alpha 数据库恢复演练记录（2026-09-26）

## 范围

- 环境：本地 Docker Desktop + WSL 2，仅使用合成 Alpha 数据。
- 后端镜像：`sha256:3f0f16a13da4e7042ec6448909dae2d76e7901dfa2995332ff0606af69e7bf49`。
- 数据库：PostgreSQL 17；缓存：Redis 7。
- 未访问生产环境、真实密钥或真实用户数据。

## 演练步骤与证据

1. 启动 PostgreSQL、Redis、迁移任务和 API；六个 Alembic 迁移顺序执行成功。
2. 确认 API 使用非 root 用户 `tianrenlu`，`/health/ready` 返回数据库与 Redis 均为 `ok`。
3. 使用 `backup-postgres.sh` 生成 PostgreSQL CUSTOM 格式备份，大小 16,936 字节。
4. SHA-256 校验通过：
   `bbb0751de7674ec6b3643419cacfee04371db49795ff4fb84d1976a9f9d6b246`。
5. 使用固定确认词执行 `restore-postgres.sh`；测试 API 被停止，备份恢复后重新执行迁移。
6. API 自动重启并恢复健康，PostgreSQL、Redis 和 `/health/ready` 最终均通过。

## 结果

- 结果：通过。
- 本次合成环境数据 RPO：0。
- 实测恢复用时：约 1 分钟，低于 Alpha RTO 4 小时目标。
- 临时备份在记录证据后删除；验证容器停止，未删除本地测试数据卷。

## 尚需人工完成

- 正式 Alpha 发布前，由指定恢复负责人使用加密异地备份在隔离服务器复演并签字。
- 对接真实存储后验证备份加密、保留 14 天、失败告警和访问控制。
- 自动 CI 恢复演练通过后，仍不能替代每月人工恢复演练。
