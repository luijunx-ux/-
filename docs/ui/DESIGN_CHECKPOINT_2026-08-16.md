# 天人律 UI 设计检查点（2026-08-16）

## 已确认成果

- Forest Life 与 Obsidian Life 两套主题的配色方案已通过视觉确认。
- Forest 首页视觉小样已通过视觉确认。
- 已通过小样保存在 [`previews/forest-home-approved-v1.png`](previews/forest-home-approved-v1.png)。
- Figma 主文件：[天人律 APP UI V3.0 — Forest / Obsidian](https://www.figma.com/design/j32IVqCeGGIURjpDatwPlH)

## Forest 首页已冻结方向

- 使用用户提供的荷叶露珠图片作为沉浸式背景基线。
- 深绿渐变遮罩与半透明玻璃卡片保证文字可读性。
- 首页保持“五运六气”和“星辰节律”同等级双核心入口。
- 生命状态球使用叶脉、露珠与柔光意象，不使用宿命化评分表达。
- 今日建议采用可执行、温和、非医疗诊断的短卡片结构。

## 当前实现状态

- 视觉小样已保存在仓库工作区，尚未写回 Figma 主文件。
- 2026-08-17 已生成 Forest / Obsidian Web 与 Android 首页真实运行截图，详见 [`UI_REVIEW_2026-08-17.md`](UI_REVIEW_2026-08-17.md)。
- Figma 当前为 Starter 方案：已有 3 个页面，变量集合仅支持单模式。
- 上次写入因 Figma MCP 调用额度限制中断，不代表视觉方案失败。
- Flutter 工作区已有 UI 相关未提交修改，继续前需按 V3.0 基线核对并保留现有成果。

## 尚待完成

1. 将已通过的 Forest 首页拆分为可编辑组件并写回 Figma。
2. 完成 Obsidian 首页高保真视觉小样并提交用户确认。
3. 补齐两套主题的详情页、状态页及组件状态。
4. 将通过审核的视觉层实现到 Flutter，输出双主题实机或模拟器截图。
5. 按 `UI_ACCEPTANCE_CRITERIA.md` 完成自检。
6. 只有在用户明确回复“视觉审核通过”后，才允许执行 Git 暂存、提交和推送。

## 恢复顺序

1. 阅读 `PROJECT_CONTEXT.md`。
2. 阅读 `REQUIREMENTS_BASELINE.md`。
3. 阅读 `CURRENT_SPRINT.md`。
4. 阅读 Forest / Obsidian UI 规范与 UI 验收标准。
5. 以本检查点和已通过图片为视觉事实源继续，不回退至旧 V1/V2 方案。
