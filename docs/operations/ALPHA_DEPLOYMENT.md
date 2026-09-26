# Alpha 部署说明

## 部署边界

该配置用于受控 Alpha，不代表公开医疗或大规模生产服务。API 默认只绑定宿主机
`127.0.0.1:8000`，应由已配置 TLS、访问日志脱敏和请求大小限制的反向代理对外提供服务。
PostgreSQL 和 Redis 不暴露宿主机端口。

## 前置条件

- Docker Engine 与 Compose 插件可用。
- 使用独立服务器和受控账号；系统时间同步，磁盘加密和安全更新已启用。
- 生产变量存放在 Git 之外的密钥管理系统或权限为 `600` 的文件中。
- 域名、TLS、SMTP 发件域验证和告警接收人已经准备。
- 已指定发布负责人、安全/隐私审核人、数据恢复负责人和产品人工审核人。

## 首次部署

1. 将 `infrastructure/docker/production.env.example` 复制到仓库外的安全位置。
2. 替换所有模板值；数据库密码写入 `DATABASE_URL` 时必须进行 URL 编码。
3. 保持 `AI_ENABLED=false` 完成基础冒烟测试；确认后再配置模型密钥并启用。
4. 校验配置：

   ```sh
   docker compose --env-file /secure/tianrenlu.env \
     -f infrastructure/docker/docker-compose.prod.yml config --quiet
   ```

5. 构建并启动。迁移服务成功退出后，API 才会启动：

   ```sh
   docker compose --env-file /secure/tianrenlu.env \
     -f infrastructure/docker/docker-compose.prod.yml up -d --build
   ```

6. 从服务器本机检查 `/health/live` 与 `/health/ready`，再执行 Alpha 发布清单。

## Android Alpha 签名

`release` 构建禁止使用调试密钥。签名负责人应将
`frontend/android/key.properties.example` 复制为 `frontend/android/key.properties`，在 Git 外提供专用
keystore 和密码，再执行 Release 构建。没有配置时构建会快速失败。内部功能验证可使用 Debug APK，
但必须明确标注“内部测试、不可发布”。

## 更新与回滚

更新前必须先备份并记录当前镜像摘要、Git 提交和数据库迁移版本。部署使用不可变镜像标签，
不得只使用 `latest`。应用异常时回退到上一镜像；数据库仅在已验证向后不兼容且恢复负责人批准时
执行恢复。不可逆迁移必须在合并前提供对应恢复方案。

## 日志与告警

- 采集 API JSON 日志，但不得采集请求正文、查询参数、Authorization、Cookie 或精确出生资料。
- 以 `request_id` 关联事件；对就绪检查连续失败、`5xx` 比例和请求耗时 P95 配置告警。
- 只有授权的运维人员可读取日志，并按隐私政策设置最短必要保留时间。
