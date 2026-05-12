---
prd_id: "{slug}"
title: "{PRD 标题}"
feishu_url: ""
feishu_doc_token: ""
version: "1.0"
created: "{YYYY-MM-DD}"
status: draft
project: ""
target_version: ""
---
<title>{PRD 标题}</title>

# 1. 版本信息

<grid>
<column width-ratio="0.333333">
<callout emoji="⏰">
1. 版本号：1.0
</callout>
</column>
<column width-ratio="0.333333">
<callout emoji="📆">
1. 创建日期 {YYYYMMDD}
</callout>
</column>
<column width-ratio="0.333333">
<callout emoji="👮">
1. 审核人 TBD
</callout>
</column>
</grid>

# 2. 变更日志

<table><colgroup><col/><col/><col/><col/></colgroup><tbody><tr><td><b>时间</b></td><td><b>版本号</b></td><td><b>变更人</b></td><td><b>主要变更内容</b></td></tr><tr><td>{YYYYMMDD}</td><td>1.0</td><td>{创建人}</td><td>创建文档</td></tr></tbody></table>

# 3. 整体说明

## 3.1 整体变更

| 原始问题 | 变更内容 | 变更类型 | 目标版本 |
| --- | --- | --- | --- |
| {原有问题} | {修改后方案} | 新增/优化/删除 | {26.x.1.0 \| TBD} |

## 3.2 范围说明

| In Scope | Out of Scope |
| --- | --- |
| {明确包含} | {明确排除，防止镀金} |

# 4. 需求详细设计

> 每个大纲一级项 = 一个 `##` 小节；子项 = `###` 小节。
> 每节按 `prd-writing-rules.md` 三规范书写：结构化语言、数据/状态驱动、背景 + 验收标准。

## {功能模块 1}

**背景：** {为什么做、来自哪个业务场景}

**需求描述：**
{用结构化语言描述功能逻辑：触发条件 + 执行动作 + 预期结果}

**验收标准：**
- [ ] {可量化的验收条件 1}
- [ ] {可量化的验收条件 2}
- [ ] {异常 / 边界场景验收条件}

### {子场景 1.1}

**触发条件：** TBD
**预期结果：** TBD
**边界：** TBD

### {子场景 1.2}

**触发条件：** TBD
**预期结果：** TBD

## {功能模块 2}

**背景：** TBD

**需求描述：** TBD

**验收标准：**
- [ ] TBD
- [ ] TBD

# 5. 功能清单

> ⚠️ **下游依赖**：此表格被 `lark-workflow-prd-to-userstory` 解析为 User Story。
> 表头、优先级取值（P0/P1/P2）、开发状态（待开发/开发中/已上线）必须保持以下格式。

| 功能模块 | 功能描述 | 优先级 | 开发状态 | 备注 |
| --- | --- | --- | --- | --- |
| {功能模块 1} | {一句话功能描述} | P0 | 待开发 | 需求详细设计 §{功能模块 1} |
| {功能模块 2} | {一句话功能描述} | P0 | 待开发 | 需求详细设计 §{功能模块 2} |

# 6. Open Questions

| 编号 | 所在章节 | 问题描述 | 负责人 | 状态 |
| --- | --- | --- | --- | --- |
| — | — | 暂无未解决问题 | — | — |

# 7. 附录

- 参考文档：{填入历史 PRD 路径或飞书 URL，可空}
- 术语表：TBD
