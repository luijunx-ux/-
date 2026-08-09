# 天人律 AI 生命节律 Agent

面向移动端的 AI 生命节律应用工程。本阶段仅完成工程初始化，不包含业务逻辑或功能实现。

## 产品范围

- 采集出生年月日、时间与地点
- 生成个人生命档案
- 计算五运六气
- 计算星座信息
- 生成每日 AI 生命建议

## 技术架构

- 移动端：Flutter
- 后端：Python + FastAPI
- 数据库：PostgreSQL
- AI：LLM + Agent + RAG

## 目录说明

```text
frontend/       Flutter 移动端工程边界
backend/        FastAPI 后端工程边界
ai/             Agent、RAG、提示词与评测资源
database/       数据库迁移、种子数据与设计文档
infrastructure/ 容器、部署与环境基础设施
docs/           架构、规范、产品与 API 文档
scripts/        开发、检查、构建和发布脚本
tests/          跨模块集成与端到端测试
```

## 开始开发前

1. 复制根目录 `.env.example` 为 `.env`，按本地环境填写配置；不要提交 `.env`。
2. 阅读 `docs/development-standards.md`。
3. 在后续阶段分别初始化 Flutter 与 FastAPI 的依赖清单和可运行入口。
4. 所有密钥通过环境变量或密钥管理服务提供，不写入源码。

## 当前状态

阶段一：工程初始化。业务代码、数据库模型、算法、API 与 UI 均尚未实现。

