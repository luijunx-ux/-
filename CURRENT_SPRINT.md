# CURRENT SPRINT：UI 基线恢复与视觉纠偏

版本目标：v0.2.0-design-alignment
状态：进行中，等待视觉实现与审核

## 背景

当前仓库的功能开发已超出原路线图早期阶段，但 Flutter Demo 未沿用已冻结的森林生命与黑曜生命视觉方向。保留现有功能，不回退业务成果；当前优先恢复产品信息架构和 UI 视觉基线。

## 本 Sprint 目标

1. 固化产品、阶段、UI 和页面验收基线。
2. 建立语义化双主题 token 与共用组件。
3. 重做首页，使双核心入口和四类建议符合基线。
4. 对齐五运六气、星辰节律、AI 生命球和档案页面。
5. 在 Web 与 Android 模拟器输出 Forest/Obsidian 对照截图。
6. 经用户明确视觉审核通过后，才允许提交和推送。

## 当前允许

- 文档、设计 token、主题、共用组件和页面 UI 重构
- 保持 API 行为不变的展示层适配
- Widget/UI 测试、截图测试、Web/Android Demo 构建
- 修复阻碍视觉验收的明确缺陷

## 当前暂停

- 新业务功能、P1/P2 能力和架构扩张
- 未经确认修改核心算法、数据库字段或公共 API
- Git 暂存、提交和推送

## Definition of Done

- `docs/ui/UI_ACCEPTANCE_CRITERIA.md` 全部硬性项通过。
- Forest 与 Obsidian 首页及关键页面均有真实运行截图。
- 视觉层次、可读性、溢出、字体缩放和减少动画模式完成自检。
- 自动测试与 Flutter analyze/build 通过。
- 用户明确回复“视觉审核通过”。
