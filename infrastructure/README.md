# Infrastructure

本目录包含本地依赖和 Alpha 环境的容器化配置：

- `docker/docker-compose.yml`：开发环境 PostgreSQL 与 Redis。
- `docker/docker-compose.prod.yml`：Alpha API、迁移、PostgreSQL 与 Redis 编排。
- `docker/production.env.example`：生产变量名称示例，不包含可用密钥。
- `scripts/backup-postgres.sh`：生成 PostgreSQL 自定义格式备份和 SHA-256 校验文件。
- `scripts/restore-postgres.sh`：经显式确认后执行恢复、迁移并重启 API。

部署和恢复步骤分别见 [`docs/operations/ALPHA_DEPLOYMENT.md`](../docs/operations/ALPHA_DEPLOYMENT.md)
和 [`docs/operations/BACKUP_RECOVERY.md`](../docs/operations/BACKUP_RECOVERY.md)。
