# PostgreSQL 备份与恢复

## Alpha 目标

- RPO（可接受数据丢失窗口）：24 小时。
- RTO（目标恢复时间）：4 小时。
- 每日自动备份，至少保留 14 天；备份必须加密并存放在与运行服务器隔离的位置。
- 每月至少在隔离环境完成一次恢复演练，禁止使用真实用户数据进行普通开发测试。
- GitHub Actions 每次变更都使用一次性合成数据库执行备份与恢复冒烟测试；该自动检查不能替代
  每月人工隔离恢复演练和负责人签字。

Redis 只承载限流与可重建状态，不作为用户数据事实源；恢复重点为 PostgreSQL。

## 创建备份

在已经加载安全环境变量的主机上运行：

```sh
BACKUP_DIR=/secure/backups sh infrastructure/scripts/backup-postgres.sh
```

脚本生成 PostgreSQL 自定义格式备份和对应 SHA-256 文件。随后应由受控任务完成加密、异地复制、
保留期限和失败告警。未经验证的空文件不得视为成功备份。

## 恢复演练

1. 获得数据恢复负责人批准，建立隔离环境并记录恢复工单、备份时间和目标版本。
2. 校验备份文件及 SHA-256；确认目标数据库允许被覆盖。
3. 设置与目标环境匹配的 `COMPOSE_FILE`，显式确认后运行：

   ```sh
   CONFIRM_RESTORE=RESTORE_TIANRENLU \
     sh infrastructure/scripts/restore-postgres.sh /secure/backups/tianrenlu-YYYYMMDDTHHMMSSZ.dump
   ```

4. 验证迁移到最新版本、`/health/ready` 返回成功、账户隔离和删除级联正常。
5. 使用合成 Alpha 账号完成注册、登录、档案读写、每日建议和注销冒烟测试。
6. 记录实际 RPO/RTO、数据量、校验结果和问题；演练环境验证后销毁。

## 生产事故约束

- 恢复脚本会停止 API，并要求固定确认词，不能由未经授权的自动任务直接触发。
- 恢复前保存故障现场和当前数据库快照；不得为快速恢复而关闭鉴权、审计或数据隔离。
- 需要通知用户或监管方时，由隐私负责人根据适用政策和事件影响作出决定。
