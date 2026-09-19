# 首页核心板块设计记录（2026-09-11）

状态：完整首页概念视觉已于 2026-09-18 获用户明确回复“视觉审核通过”；Vitality Flutter 首页及“正念冥想”入口已于 2026-09-19 通过视觉审核
适用主题：Vitality Life 概念稿；Forest Life / Obsidian Life 后续复用相同信息架构
Git 状态：AI 综合分析详情页已通过视觉审核，待提交并推送

## 1. 本次保存范围

| 板块 | 首页/详情结构 | 预览图 | 可交互原型 | 当前审核说明 |
|---|---|---|---|---|
| AI 综合分析 | 完整详情页 | [`ai-analysis-page-v1.png`](previews/vitality/ai-analysis-page-v1.png) | [`ai-analysis-page-v1.html`](prototypes/vitality/ai-analysis-page-v1.html) | 已完成样板，等待后续整体视觉确认 |
| 五运六气 | 首页摘要 + 双列详情 | [`yunqi-home-module-v1.png`](previews/vitality/yunqi-home-module-v1.png)、[`yunqi-detail-page-v1.png`](previews/vitality/yunqi-detail-page-v1.png) | [`yunqi-flow-v1.html`](prototypes/vitality/yunqi-flow-v1.html) | 用户已回复“这个结果通过”；Git 视觉门禁仍以明确“视觉审核通过”为准 |
| 星辰节律 | 首页摘要 + 双列详情 | [`stellar-home-module-v1.png`](previews/vitality/stellar-home-module-v1.png)、[`stellar-detail-page-v1.png`](previews/vitality/stellar-detail-page-v1.png) | [`stellar-rhythm-flow-v1.html`](prototypes/vitality/stellar-rhythm-flow-v1.html) | 已完成样板，等待后续整体视觉确认 |
| 四类生活建议 | 首页四卡 + 单项展开 | [`daily-advice-module-v1.png`](previews/vitality/daily-advice-module-v1.png) | [`daily-advice-module-v1.html`](prototypes/vitality/daily-advice-module-v1.html) | 已完成样板，等待后续整体视觉确认 |

上述 HTML 是设计原型，不是生产代码，不得直接当作 Flutter 实现或业务规则来源。

## 2. 已确定的信息结构

### 2.1 AI 综合分析

1. 今日核心判断。
2. 状态说明。
3. 最多三项主要依据及数据来源。
4. 唯一的“今日优先行动”。
5. “为什么这样建议”可展开说明。
6. “问问天人律”快捷问题与自由输入入口。
7. 反馈及非医疗声明。

生命参考分必须来自 `life-reference-v0.1` 规则引擎；LLM 只解释结构化结果。

### 2.2 五运六气

- 首页提供摘要、通俗结论、生活提示和详情入口。
- 详情使用“专业术语 / 普通人怎么理解”双列结构。
- 展示节气、地点、天气/空气数据状态和更新时间。
- 饮食、睡眠、活动、情绪建议置于分析内容下方。
- 五运六气结果由确定性引擎计算；具体知识解释须通过专家及黄金测试集审核。
- 不把五运六气解释成疾病、吉凶或必然事件，也不直接增减生命参考分。

### 2.3 星辰节律

- 与五运六气保持同等级入口、接近的信息量和相同的导航深度。
- MVP 仅使用太阳星座；月亮和上升星座后置。
- 详情使用“专业术语 / 普通人怎么理解”双列结构。
- 重点是专注、沟通、情绪和休息的开放式自我观察。
- 禁止桃花、财富、吉凶和具体事件预测。
- 星辰节律不直接增减生命参考分。

### 2.4 四类生活建议

- 首页固定显示饮食、睡眠、活动、情绪四类摘要。
- 点击分类后，只展开一个分类的具体行动、两步做法、依据和反馈。
- AI 综合分析中的“今日优先行动”是唯一主任务；四类建议只提供分类补充。
- 同一行动不得在 AI、五运六气、星辰节律和四类建议中重复形成多个主任务。
- 用户可以完成、跳过、调整或请求替换建议。

## 3. 内容合并与去重规则

1. 规则引擎先返回事实、状态、来源和候选建议主题。
2. AI 综合分析只选择一个跨类别优先行动。
3. 四类建议分别保留一个分类摘要和最多两个补充步骤。
4. 五运六气与星辰节律只作为文化及节律解释背景，不产生健康事实。
5. 相同行动文本按语义归并；优先保留依据更直接、数据更新更及时的版本。
6. 缺失数据不补零、不伪造，不足以个性化时使用经审核的通用温和建议并明确说明。

## 4. 后续开发门禁

- 先完成“我的重点状态与今日记录”、底部导航和完整首页串联。
- 完整首页视觉通过后，再把冻结结构转成 Flutter 组件。
- Flutter 实现后必须提供 Forest、Obsidian、Vitality 的真实运行截图和窄屏/大字体状态。
- 用户明确回复“视觉审核通过”前，不执行 `git add`、`git commit` 或 `git push`。

## 5. 已知问题

- 当前图片及文案使用示例数据，只用于视觉排版。
- 五运六气具体知识内容尚未完成专家审核。
- 星辰节律的每日解释模板、资料来源和版本控制尚待专题规范。
- 四类建议的服务端聚合契约、去重算法和安全审核尚未设计完成。
- Vitality Life 尚未进入冻结需求中的正式开发排期；P0 仍以 Forest Life / Obsidian Life 为基线。

## 6. Flutter 实现记录（2026-09-18）

- 新增 Vitality Life 主题 Token 与主题切换入口，Forest Life 仍为默认主题。
- 完整首页已接入每日生活主图、数据状态窗口、AI 综合分析、同等级双核心入口、四类建议、重点状态记录及底部导航。
- 未获得真实健康平台授权时，生命参考状态、步数、睡眠与 Readiness 显示明确缺失状态，不使用概念稿示例数值。
- 重点状态支持本地单次交互反馈；本轮未新增服务端持久化接口，也不会回写生命参考分。
- Flutter 全量测试 21 项通过；Vitality 视觉基线保存为 [`review/vitality-home-mobile-v4.png`](review/vitality-home-mobile-v4.png)。
- Flutter 静态分析器在当前 Windows 中文工程路径下发生 LSP JSON 解析故障，属于工具环境问题，需迁移至纯英文路径后补跑。

## 7. 正念冥想入口（2026-09-19）

- “今天怎样照顾自己”板块在四类生活建议之后新增“正念冥想”按钮。
- 当前按钮仅展示未来接入说明，不唤起外部应用、不上传个人数据、不生成冥想效果评分。
- 后续与“冥想室”应用打通前，必须单独评审 Deep Link/App Link、用户授权、数据最小化、失败降级和隐私说明。
- 冥想记录如未来参与任何状态计算，必须先形成可测试的冻结规则；LLM 不得自行据此修改生命参考分。

## 8. AI 综合分析 Flutter 详情页（2026-09-19）

- Vitality 首页的 AI 分析卡片已接入独立 Flutter 详情页；Forest Life 与 Obsidian Life 暂时保留原有建议页，避免未经视觉审核改变双主题。
- 页面复用现有每日建议接口，呈现核心判断、最多三类主要依据、唯一优先行动、解释入口、快捷问题、反馈与非医疗边界说明。
- 未获得健康平台授权时明确显示“生命参考分：数据不足”和“健康与设备数据：尚未授权”，不使用概念稿中的示例分数、步数、睡眠或 Readiness 数值。
- “问问天人律”当前只展示后续接入说明，不上传新的健康信息，不把用户问题作为生命参考分输入。
- 视觉审核基线：[`review/vitality-ai-analysis-mobile-v1.png`](review/vitality-ai-analysis-mobile-v1.png)；用户已于 2026-09-19 明确回复“视觉审核通过”。
