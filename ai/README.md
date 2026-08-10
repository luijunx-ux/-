# AI

天人律的 LLM、Agent、RAG、提示词与评测资产工程边界。

## 当前实现

- 确定性程序负责星座与五运六气计算。
- `DailyAdviceAgent` 编排基础建议、Markdown 知识检索和 LLM 表达增强。
- OpenAI Responses API 使用严格 JSON Schema，且设置 `store: false`。
- 发送给模型的上下文不包含出生地点、经纬度或精确出生时刻。
- 缺少密钥、模型超时、拒绝或输出校验失败时自动返回确定性建议。
- 输出在返回用户前经过医疗、风险预测、宿命论和结构安全门禁。
- 审计日志仅记录随机请求 ID、模型、生成模式、Token、知识来源数量和安全结果。
- 不在代码中硬编码模型价格；成本系统依据审计 Token 与部署时价格表计算。

## 启用 AI

默认 `AI_ENABLED=false`。在本地 `.env` 中配置以下变量后重启后端：

```dotenv
AI_ENABLED=true
LLM_API_KEY=<secret>
LLM_MODEL=gpt-5.6-terra
```

不要将真实密钥写入仓库。正式上线前必须通过评测集验证建议质量、健康边界、延迟和成本。

## 评测

版本化安全评测集位于 `evaluations/datasets/advice_safety_v1.jsonl`，并由后端测试自动执行。
新增安全规则或提示词时必须同步增加正常与违规案例，避免只提升拦截率却扩大误拦截。

## 知识库

`rag/knowledge/` 当前采用可审查的 Markdown 资料和本地词法检索。后续接入向量库时，应保留
来源、版本、授权信息和检索命中记录。
