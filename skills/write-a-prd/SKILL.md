---
name: write-a-prd
description: "PRD 写作工作流：从功能大纲同时生成本地 Markdown PRD 与飞书云文档 PRD 骨架，按统一章节规范（§1 版本信息 / §2 变更日志 / §3 整体说明 / §4 需求详细设计 / §5 功能清单 / §6 Open Questions / §7 附录）输出，便于后续用 lark-workflow-prd-sync 同步、lark-workflow-prd-to-userstory 拆成 User Story。当用户需要创建新 PRD、写 PRD、PRD 初稿、PRD 骨架、write-a-prd、起草产品需求文档时使用。"
metadata:
  author: 雪松-Ash Zeng
  version: 3.0.0
  requires:
    bins: ["lark-cli"]
---

# PRD 写作工作流

**CRITICAL — 开始前 MUST 用 Read 工具读取以下文件：**

1. [`prd-template.md`](prd-template.md) — PRD 骨架模板（含 YAML frontmatter + 统一章节编号）
2. [`prd-writing-rules.md`](prd-writing-rules.md) — PRD 编写规范（结构化语言、三要素、验收标准）
3. [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md)（若存在）— lark-cli 认证与权限

---

## PRD 三件套流程

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────────┐
│  write-a-prd    │────►│  prd-sync        │────►│  prd-to-userstory       │
│  (本 skill)     │     │  飞书 ↔ 本地同步  │     │  PRD → User Story       │
│                 │     │                  │     │  → 需求矩阵 → 飞书项目   │
│  触发：          │     │  触发：           │     │  触发：                  │
│  写PRD/创建PRD   │     │  prd sync        │     │  prd-to-userstory       │
│  write-a-prd    │     │  prd同步          │     │  功能清单转user story    │
└────────┬────────┘     └────────┬─────────┘     └────────┬────────────────┘
         │                       │                        │
         ▼                       ▼                        ▼
   [HANDOFF 交接]          [HANDOFF 交接]           [最终对照表]
   local_path              local_path               Base record_id
   feishu_url              version                  飞书项目 work_item_id
   doc_token               feature_count
   status: draft           unresolved_oq
```

每个 skill **独立可用**。串联使用时通过 `[HANDOFF]` 块和 PRD frontmatter 自动传递上下文。

---

## 适用场景

- "写 PRD / 起草 PRD / 创建 PRD 初稿"
- "从功能大纲生成 PRD 骨架"
- "write-a-prd {功能名}：{大纲}"
- "把这些功能整理成 PRD"

## 输入

| 参数 | 示例 | 说明 |
|------|------|------|
| **PRD 标题** | `PST 用户体验优化V1` | 用于文档标题、文件名、飞书文件名 |
| **功能大纲** | 见下方示例 | bullet list，支持嵌套（用于 §4 需求详细设计与 §5 功能清单） |
| **参考文档**（可选） | 历史 PRD 路径或 `/graphify` 产物 | 用于对齐历史模式、避免重复发明 |
| **目标版本**（可选） | `26.5.1.0` | 写入 §3.1 整体变更 + frontmatter.target_version |
| **项目代号**（可选） | `PST` | 写入 frontmatter.project，供下游 prd-to-userstory 使用 |

**输入示例：**

```
/write-a-prd PST 用户体验优化V1
- 工作站提醒
  - 工作站数量不足时 Autolayout 弹窗 + Summary 标记
- 车效提醒
  - 车效超出标准区间弹窗 + Summary 标记
- 自动布局限制
  - 地图小于 15m×15m 时禁止自动布局
- HPS5 关键假设简化
- 3D 按钮禁用
- 单位规范更新
- 需求测算筛选

/graphify 参考文档
- HPS3-V1R3 -PST V1需求文档
- HPC V1R2 PST - PRD
```

## 前置条件

```bash
# 飞书云文档（user 身份）
lark-cli auth login --domain docs,drive,wiki
```

## 工作流

```
{PRD 标题, 功能大纲, [参考文档], [目标版本], [项目代号]}
        │
        ▼
Step 1  扫描输入 ──► 确认本地落盘路径（prd/{年}/{月}/{slug}-prd.md）
        │
        ▼
Step 2  Load References（可选）
        ├─ 读取历史 PRD 或 /graphify 产物
        ├─ 提取可复用的章节结构、术语、验收标准写法
        ▼
Step 3  生成本地 Markdown PRD 骨架（基于 prd-template.md）
        ├─ 填充 YAML frontmatter（prd_id / title / created / project / target_version）
        ├─ 按大纲填 §4 需求详细设计子章节
        ├─ 按大纲填 §5 功能清单表格（每条标记 P0 / 待开发）
        ├─ 模糊值一律写 TBD，不猜测
        ▼
Step 4  生成飞书云文档 PRD 骨架
        ├─ docs +create --api-version v2 --doc-format markdown
        ├─ 首行 <title>、版本信息用 <grid>/<callout>、变更日志用 <table>
        ├─ 正文章节与本地 md 完全对齐
        ├─ 记录飞书 URL / doc_token，回写本地 md 的 frontmatter
        ▼
Step 5  输出给用户 + [HANDOFF] 交接块
```

---

## Step 1：确定本地落盘路径

```bash
YEAR=$(date +%Y)
MONTH=$(date +%-m)
SLUG={PRD 标题 → kebab-case}   # 例："PST 用户体验优化V1" → "pst-ux-v1"

mkdir -p prd/${YEAR}/${MONTH}
FILE="prd/${YEAR}/${MONTH}/${SLUG}-prd.md"
```

- 用 AskUserQuestion 确认 SLUG（避免中文文件名）
- 若目标目录已有同名文件，询问用户选择「覆盖 / 新建 -v2 / 中止」

## Step 2：Load References（可选）

按用户提供的参考列表读取：

- **本地路径**：直接 Read
- **飞书 wiki URL**：`lark-cli docs +fetch --api-version v2 --doc "{URL}" --doc-format markdown`
- **/graphify 产物**：加载 graph JSON

**提取目标：**
- 术语表（保证新 PRD 术语一致）
- 相似需求的验收标准写法
- 历史遗留问题（可能与本次 PRD 耦合）

若无参考，跳过本步，但在 §6 Open Questions 里标注「无历史参考，术语与边界待评审」。

## Step 3：生成本地 Markdown PRD

基于 [`prd-template.md`](prd-template.md) 的骨架，按大纲填充。

**YAML frontmatter 填充：**

```yaml
---
prd_id: {SLUG}
title: {PRD 标题}
feishu_url: ""              # Step 4 回填
feishu_doc_token: ""        # Step 4 回填
version: "1.0"
created: {YYYY-MM-DD}
status: draft
project: {项目代号，未提供则留空}
target_version: {目标版本号，未提供则留空}
---
```

**章节与填充规则：**

| 章节 | 填充策略 |
|------|---------| 
| `<title>{PRD 标题}</title>` | frontmatter 之后的首行 |
| `# 1. 版本信息` | 版本号 `1.0`、创建日期 `YYYYMMDD`、审核人留空 |
| `# 2. 变更日志` | 首行 `YYYYMMDD` / `1.0` / 创建人 / `创建文档` |
| `# 3. 整体说明` → `## 3.1 整体变更` | 按目标版本填一句话概述；逐项变更留 TBD |
| `# 4. 需求详细设计` | **每个大纲一级项 = 一个 `##` 小节**；子项 = `###` |
| `# 5. 功能清单` | 表头 `功能模块 \| 功能描述 \| 优先级 \| 开发状态 \| 备注`；每行对应一个 §4 小节，优先级默认 P0，开发状态默认「待开发」，备注引用 `需求详细设计 §<章节标题>` |
| `# 6. Open Questions` | 空表或列出 Step 2 识别的待澄清问题 |
| `# 7. 附录` | 空 |

**填充约束（参考 `prd-writing-rules.md`）：**

1. **三要素齐全**：每条需求描述都包含触发条件 + 执行动作 + 预期结果
2. **拒绝模糊词**：禁用"适当"、"合理"、"友好"、"快速"等；无法量化的值写 `TBD`
3. **边界场景**：每条需求至少列一条异常/边界
4. **背景 + 验收标准**：按 `prd-writing-rules.md` 格式模板逐条写
5. **不臆造未提供的数据**：用户大纲里没说的值 → `TBD`

**落盘：**

```
Write {FILE}
```

## Step 4：生成飞书云文档 PRD 骨架

```bash
lark-cli docs +create \
  --api-version v2 \
  --doc-format markdown \
  --content "$(cat {FILE})"
```

返回示例：
```
{
  "doc_token": "xxx",
  "url": "https://hairobotics.feishu.cn/wiki/xxx"
}
```

**同步关键点：**

- **YAML frontmatter** → 飞书不会渲染 frontmatter，上传的 markdown 内容应**跳过 frontmatter 部分**（从 `<title>` 行开始）
- **首行 `<title>`** → 飞书会识别为文档标题
- **版本信息章节** → 用 `<grid>` + `<callout>` 结构（模板里已给好）
- **变更日志** → 用 `<table>` 结构
- **其他章节** → 纯 Markdown，飞书自动渲染

**回写本地 md frontmatter：** 更新 `feishu_url` 和 `feishu_doc_token` 字段。

**可选：移动到知识库。** 若用户要求放到团队 wiki 空间：

```bash
lark-cli wiki +space-list
lark-cli wiki +node-move --doc-token {doc_token} --target-space-id {space_id} --parent-node {parent_node_id}
```

## Step 5：输出给用户

```
✅ PRD 骨架已生成

📄 本地文件：prd/2026/5/pst-ux-v1-prd.md
🔗 飞书文档：https://hairobotics.feishu.cn/wiki/XXXXXXX

下一步建议：
1. 打开飞书文档或本地 md，细化 §4 需求详细设计（可告诉我「细化 §4.2」）
2. 内容稳定后：/prd-sync 飞书 ↔ 本地 双向同步
3. §5 功能清单稳定后：/prd-to-userstory 拆成 User Story 并同步到飞书项目

❓ 待澄清问题（Step 2 识别）：
- {列出遗留 TBD 项与 Open Questions}

[HANDOFF: write-a-prd → prd-sync]
- local_path: prd/2026/5/pst-ux-v1-prd.md
- feishu_url: https://hairobotics.feishu.cn/wiki/XXXXXXX
- feishu_doc_token: XXXXXXX
- version: 1.0
- status: draft（骨架已生成，§4 需求详细设计待细化）
- feature_count: {§5 功能清单行数}
- open_questions: {§6 未解决 OQ 数}
- project: {项目代号或空}
- target_version: {目标版本号或空}
```

---

## 规则

1. **Skeleton first, detail later** — PRD 是脚手架；细节由用户逐节细化，本 skill 不猜测。
2. **本地 ↔ 飞书同步首发** — 本地 md 和飞书文档内容必须一字不差（飞书多了 `<title>` / `<grid>` / `<table>` XML 元素；本地多了 YAML frontmatter）。
3. **下游可解析** — §5 功能清单的表头、优先级取值、备注格式必须与 `lark-workflow-prd-to-userstory` 约定一致，否则下游拆 Story 会失败。
4. **Reference-driven** — 有参考文档就严格对齐术语与章节结构；无参考则在 §6 Open Questions 标注风险。
5. **No implementation** — 本 skill 只产出 PRD 文件，不涉及任何代码。
6. **一次一个功能细化** — 骨架交付后，等用户给下一条指令（"细化 §4.2"、"补上 §5 的 X 行"）再进入下一轮。
7. **Frontmatter 必填** — 每个 PRD 必须有 YAML frontmatter，供下游 skill 自动读取 feishu_url / project / target_version。

## 常见问题

1. **飞书侧 `<title>` 被转义**：`docs +create` 传 markdown 时 `<title>` 会被原样写入。要让飞书把首行识别为标题，必须用 `--doc-format markdown` 且把 `<title>...</title>` 放在正文第一行。上传时跳过 YAML frontmatter。
2. **表格渲染**：飞书对纯 markdown 表格的支持有限；变更日志建议用 `<table>` / `<tbody>` / `<tr>` / `<td>` XML（模板里已给）。
3. **本地 md 包含 XML 元素**：Obsidian / VSCode markdown 预览器会原样显示 XML；需要纯净预览时复制到飞书查看。
4. **大纲里有"优化需求"类关键词**：下游 prd-to-userstory 会根据这些关键词自动判别 `【{项目}-优化需求】` 前缀，保留即可。
5. **覆盖既有飞书文档**：skill 默认只 `create`，不 `update`。修改既有 PRD 请用 `lark-workflow-prd-sync`。
6. **向下兼容**：下游 prd-sync 同时支持 frontmatter 和旧版 `<!-- 飞书文档：{URL} -->` 注释，但新建 PRD 应始终使用 frontmatter。

## 权限

| 操作 | 所需 scope |
|------|-----------|
| 创建飞书云文档 | `docs:document` |
| 移入 wiki 空间 | `wiki:wiki:write` |
| 读取历史参考 | `docs:document:readonly` |

## 参考

- [`prd-template.md`](prd-template.md) — PRD 骨架模板
- [`prd-writing-rules.md`](prd-writing-rules.md) — PRD 编写规范
- [`../lark-workflow-prd-sync/SKILL.md`](../lark-workflow-prd-sync/SKILL.md) — 飞书 ↔ 本地 增量同步
- [`../lark-workflow-prd-to-userstory/SKILL.md`](../lark-workflow-prd-to-userstory/SKILL.md) — PRD → User Story → 飞书项目
- [`../lark-doc/SKILL.md`](../lark-doc/SKILL.md)（若存在）— docs +create / +fetch / +update
