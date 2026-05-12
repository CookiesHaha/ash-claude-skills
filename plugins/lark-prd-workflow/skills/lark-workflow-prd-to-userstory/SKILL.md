---
name: lark-workflow-prd-to-userstory
description: "PRD 转 User Story 工作流：把 PRD §5 功能清单生成 P0 User Story、写入飞书需求矩阵 Base 表，并同步到飞书项目对应版本中。当用户需要从 PRD 同步需求到飞书需求矩阵和飞书项目、prd-to-userstory、把功能清单转成 user story、按版本批量创建需求、对齐需求矩阵与需求管理时使用。"
metadata:
  author: 雪松-Ash Zeng
  version: 2.0.0
  changelog: |
    2.0.0 (2026-05-09)
      - 统一 PRD 章节编号体系（§4 功能清单 → §5；§3 需求详细设计 → §4）
      - 新增 Step 0.5：优先从 [HANDOFF] 块和 YAML frontmatter 读取 project / target_version / feishu_url
      - Step 3 输出标准化 checkpoint 确认表
    1.1.0 - 初版：通用契约 + 项目实例模式
  requires:
    bins: ["lark-cli"]
    mcps: ["FeishuProjectMcp", "feishu"]
---

# PRD → User Story → 需求矩阵 → 飞书项目 工作流

**CRITICAL — 开始前 MUST 用 Read 工具读取以下文件：**

1. [`references/userstoryrule.md`](references/userstoryrule.md) — User Story 通用书写规则（INVEST、P0、格式约束、跨项目复用）
2. [`references/template-mapping.md`](references/template-mapping.md) — 字段/角色/模板映射的 **通用契约 + 项目实例**
3. [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md) — lark-cli 认证与权限处理

---

## PRD 三件套定位

```
write-a-prd ────► prd-sync ────► [本 skill: prd-to-userstory]
   (创建)           (同步)              (拆 Story + 同步到 Base / 飞书项目)
```

本 skill 是「需求落地」环节，**独立可用**：
- 上游可以是 write-a-prd + prd-sync 串联产出（自带 [HANDOFF] 块和 frontmatter），也可以是任何符合「§5 功能清单」结构的 PRD（手写/历史 PRD）
- 通过 `template-mapping.md` 的「项目实例」段落注入差异，主流程不变

> 本 skill 与具体产品线（PST / CPQ / WLS / 其他）解耦。

---

## 适用场景

- "把 PRD 同步到需求矩阵和飞书项目"
- "从 PRD 的功能清单生成 user story"
- "按版本批量创建需求"
- "对齐 {项目} 需求矩阵 v{版本} 与飞书项目 {项目}-{版本}"

## 输入

| 参数 | 示例 | 说明 |
|------|------|------|
| **项目代号** | `PST` / `CPQ` / `WLS` 等 | 决定加载 `template-mapping.md` 中的哪个项目实例。可从 PRD frontmatter.project 读取；都没有时用 AskUserQuestion |
| **PRD 版本号** | `26.5.1.0` | 飞书项目对应版本工作项需提前建好，名为 `{项目}-{版本号}`。可从 PRD frontmatter.target_version 读取 |
| **PRD 来源** | 本地目录 `prd/2026/5/` 或飞书 wiki URL | 二选一；本地优先。若前置 skill 输出了 [HANDOFF]，自动读取 local_path |

如上述信息从 [HANDOFF] / frontmatter 都拿不到，**用 AskUserQuestion** 询问，不要猜。

## 前置条件

```bash
# 飞书 Base + 文档（user 身份）
lark-cli auth login --domain bitable,docs,drive

# 飞书项目 MCP 已配置（mcp__FeishuProjectMcp__*）
# 飞书云文档 MCP 已配置（mcp__feishu__*，仅在跨 wiki 读取 PRD 时使用）
```

另需在 `references/template-mapping.md` 中**提前配好目标项目的实例**（首次跑某个项目时，约 5 分钟一次性维护工作）。

## 工作流

```
{项目代号, PRD 版本号, PRD 来源}
        │
        ▼
Step 0    加载项目实例配置（template-mapping.md 中的 PROJECTS[{项目}]）
          │
        ▼
Step 0.5  从 [HANDOFF] / frontmatter 自动填充缺失参数
          │
        ▼
Step 1    扫描 PRD 来源 ──► 让用户确认本次同步的 PRD 文件
          │
        ▼
Step 2    Read PRD ──► 提取 §5 功能清单 + 引用的 §4 需求详细设计章节
          ├─ 按 mapping.title_prefix_rules 自动判别标题前缀
          ▼
Step 3    生成 P0 User Story 草稿（依据 references/userstoryrule.md）
          ├─ 父子去重：识别覆盖关系，AskUserQuestion 让用户确认合并策略
          ├─ 输出标准化 checkpoint 表，用户确认后才进入 Step 4
          ▼
Step 4    写入需求矩阵 Base 表（mapping.base.*）
          ├─ +record-search 检查同名记录避免重复
          ├─ +record-create 批量创建（字段名按 mapping.base.fields 映射）
          ▼
Step 5    同步到飞书项目（mcp__FeishuProjectMcp__）
          ├─ 5a 验证版本工作项存在
          ├─ 5b 批量 create_workitem
          ├─ 5c 设置当前用户为产品经理（必须，否则 5d 无权写）
          ├─ 5d 设置规划版本字段
          ├─ 5e 勾选节点开关
          ▼
Step 6    双向对齐核对 ──► 输出最终对照表
```

---

## Step 0：加载项目实例配置

按用户提供的「项目代号」从 [`references/template-mapping.md`](references/template-mapping.md) 中读取该项目的所有 ID 与字段映射，存入工作流上下文。后续 Step 1–6 全部用变量引用，不出现硬编码 ID。

如用户未给项目代号且 mapping 中只有一个项目实例，自动使用该实例；多于一个则用 AskUserQuestion 让用户选。

## Step 0.5：从 [HANDOFF] / frontmatter 自动填充参数

**读取优先级：**

```
① 当前对话中最近的 [HANDOFF: prd-sync → prd-to-userstory] 块
② 目标 PRD 文件的 YAML frontmatter
③ AskUserQuestion 询问用户
```

**从 [HANDOFF] 或 frontmatter 可获得：**

| 字段 | 用途 |
|------|------|
| `local_path` | Step 1 跳过文件选择 |
| `feishu_url` | Step 4 Base.fields.link 字段写入 |
| `project` | Step 0 选项目实例 |
| `target_version` | Step 5a 反查版本工作项 ID |
| `feature_count` | Step 3 数量对齐校验 |
| `unresolved_oq` | 若 > 0 且 status=draft，提示用户"PRD 含未解决 OQ，建议先完成 prd-sync 再拆 Story" |

**冲突处理：** 若 [HANDOFF] 和用户显式输入冲突，以用户显式输入为准并打印提示。

**状态守门：** 如 frontmatter.status == "draft" 或 unresolved_oq > 0，默认 AskUserQuestion：「PRD 尚在 draft 状态/含未解决 OQ，是否继续拆 Story？」用户确认才继续。

## Step 1：确定 PRD 文件

**本地目录：**

```bash
ls -1 {PRD目录}/*.md
```

列出后用 AskUserQuestion 让用户选择本次要处理的 PRD（可能多于 1 个）。单文件目录或从 [HANDOFF] 已获得 local_path 时可直接进入 Step 2。

**飞书 wiki URL：** 用 `lark-cli docs +fetch --doc {URL} --doc-format markdown` 拉取到本地临时文件后再进入 Step 2。

## Step 2：解析 PRD

```
Read {PRD文件}
```

**提取目标：**

1. **§5 功能清单**（markdown 表格，列：功能模块 | 功能描述 | 优先级 | 开发状态 | 备注）
   - 只取 `优先级 = P0` 的行；其他丢弃
   - `备注` 列里的「需求详细设计 §xxx」用于回到 PRD §4 找对应详细章节，作为 user story 验收标准的素材
2. **§4 需求详细设计**（每条 P0 对应的子章节）

**判别标题前缀：** 按 `mapping.title_prefix_rules` 中的关键词规则匹配（如 PST 项目里「优化/体验升级/UX」→ `【{项目}-优化需求】`）。无法判定时用 AskUserQuestion 让用户在该项目的可选前缀中选择。

**判别 Base 字段「需求类别」**：mapping 中可声明同样的关键词→类别映射；缺省时按项目实例的 `default_demand_category` 取值。

## Step 3：生成 User Story 草稿

按 [`references/userstoryrule.md`](references/userstoryrule.md) 的格式生成每条 user story：

```markdown
**作为** {角色}
**我希望** {功能描述}
**以便于** {业务价值}

**验收标准：**
- [ ] {可独立测试的具体条件}
- [ ] ...

**优先级：** P0（最高优先级）

**PRD：** [{PRD标题}]({PRD飞书wiki链接})
```

**INVEST 自检：**
- 不满足 Small（>3 开发日）→ 拆分为 Sub-Story（不计入主 Story 数量）
- 不满足 Independent → 标记父子关系
- 父子覆盖识别：当 A 的验收标准完整包含 B 时，向用户报告并 AskUserQuestion 选择处理方式：
  - 合并为父需求（推荐）／全部保留／仅保留小粒度

**用户确认门（标准化 checkpoint）：** 必须输出以下结构化预览表，等用户确认后才进入 Step 4。**不允许跳过这一步直接写入。**

```
[CHECKPOINT: prd-to-userstory Step 3 → Step 4]

PRD 来源：{local_path}
项目：{project}  目标版本：{target_version}
功能清单 P0 行数：{N}（若与 [HANDOFF].feature_count 不一致则标红）

拟创建的 User Story：
| # | 标题前缀 | 功能模块 | 角色 | 价值摘要 | 验收标准条数 | 拆分建议 |
|---|---------|---------|------|---------|-------------|---------|
| 1 | 【PST-优化需求】 | ... | ... | ... | N | 合并 / 保留 / 拆 Sub |
| ... |

父子覆盖冲突：{若无写「无」；否则列出冲突对与推荐策略}

确认以上清单后回复「继续」进入 Step 4；需要调整请指出具体行号。
```

## Step 4：写入需求矩阵 Base 表

参考 `mapping.base` 段落（含 app_token / table_id / 字段名）。

```bash
# 4a. 检查重复
lark-cli base +record-search \
  --app-token {mapping.base.app_token} \
  --table-id {mapping.base.table_id} \
  --filter '{"conjunction":"and","conditions":[{"field_name":"{mapping.base.fields.title}","operator":"is","value":["{标题}"]}]}'

# 4b. 批量创建（每条记录一次调用，字段名从 mapping.base.fields 取）
lark-cli base +record-create \
  --app-token {mapping.base.app_token} \
  --table-id {mapping.base.table_id} \
  --fields '{
    "{mapping.base.fields.title}": "{标题前缀}{功能名}",
    "{mapping.base.fields.description}": "{user story 正文}",
    "{mapping.base.fields.epic}": "{Epic 选项值}",
    "{mapping.base.fields.type}": "{Userstory 选项值}",
    "{mapping.base.fields.priority}": "{紧急 选项值}",
    "{mapping.base.fields.task_type}": "{产品需求 选项值}",
    "{mapping.base.fields.demand_type}": "{常规需求 选项值}",
    "{mapping.base.fields.demand_category}": "{优化需求|核心需求}",
    "{mapping.base.fields.target_version}": "{mapping.base.version_value_format 渲染后的值}",
    "{mapping.base.fields.link}": {"link":"{PRD飞书wiki链接}","text":"{PRD标题}"}
  }'
```

**提取 PRD 飞书 wiki 链接：** 优先从 frontmatter.feishu_url 读取；无则用 `lark-cli docs +search --search-key "{PRD标题}"` 找。

记录每条创建后的 `record_id` 备 Step 6 核对。

## Step 5：同步到飞书项目

参考 `mapping.feishu_project` 段落。

### 5a 验证版本

```python
mcp__FeishuProjectMcp__get_workitem_brief(
  url="https://project.feishu.cn/{mapping.feishu_project.project_key}/version/detail/{version_id}"
)
# 用户口语版本号 26.5.1.0 → 完整名 {项目代号}-26.5.1.0；
# 若用户没给 version_id，优先查 mapping.feishu_project.version_id_lookup；都没有则让 ta 提供版本工作项 URL。
```

### 5b 批量创建工作项

```python
mcp__FeishuProjectMcp__create_workitem(
  project_key="{mapping.feishu_project.project_key}",
  work_item_type="{mapping.feishu_project.work_item_type}",
  fields=[
    {"field_key":"name", "field_value":"{标题前缀}{功能名}"},
    {"field_key":"template", "field_value":"{mapping.feishu_project.template_id}"},
    {"field_key":"{mapping.feishu_project.fields.product}", "field_value":"{所属产品 option_id}"},
    {"field_key":"priority", "field_value":"{mapping.feishu_project.priority_options.urgent}"},
    {"field_key":"description", "field_value":"{user story markdown}"}
  ]
)
# 注意：mapping.feishu_project.fields.target_version 在创建时会被静默忽略，不要在这里传。
# 记录每条返回的 work_item_id。
```

### 5c 设置当前用户为产品经理（必须）

```python
# 先获取当前用户 user_key
mcp__FeishuProjectMcp__search_user_info(user_keys=["current_login_user()"])

# 给每条新需求加产品经理角色
mcp__FeishuProjectMcp__update_field(
  project_key="{mapping.feishu_project.project_key}",
  work_item_id="{work_item_id}",
  role_operate=[{"op":"add",
                 "role_key":"{mapping.feishu_project.roles.product_manager}",
                 "user_keys":["{user_key}"]}]
)
```

> **重要：** 跳过此步会让 5d 报「无权编辑 {规划版本字段名}」。

### 5d 设置规划版本

```python
mcp__FeishuProjectMcp__update_field(
  project_key="{mapping.feishu_project.project_key}",
  work_item_id="{work_item_id}",
  fields=[{"field_key":"{mapping.feishu_project.fields.target_version}",
           "field_value":"{version_work_item_id}"}]
)
```

### 5e 勾选节点开关

```python
mcp__FeishuProjectMcp__update_field(
  project_key="{mapping.feishu_project.project_key}",
  work_item_id="{work_item_id}",
  fields=[
    # 开关字段从 mapping.feishu_project.node_switches.default 中取
    # 例如 PST 项目默认开启：功能测试 / 后端开发 / 前端开发
    {"field_key":"{mapping.feishu_project.node_switches.default[0]}", "field_value":"true"},
    ...
  ]
)
```

> **不开权限受限的开关**（如 PST 中的产品设计 `field_cc5680`）：默认无权编辑，需流转后才开放。提示用户后续手动勾选。

## Step 6：双向核对

```bash
# Base 侧
lark-cli base +record-search \
  --app-token {mapping.base.app_token} \
  --table-id {mapping.base.table_id} \
  --filter '{"conjunction":"and","conditions":[{"field_name":"{mapping.base.fields.target_version}","operator":"is","value":["{版本字段值}"]}]}'
```

```python
# 飞书项目侧
mcp__FeishuProjectMcp__search_by_mql(
  project_key="{mapping.feishu_project.project_key}",
  mql="SELECT `name`, `work_item_id`, `{mapping.feishu_project.fields.target_version}` FROM `{mapping.feishu_project.project_key}`.`{mapping.feishu_project.work_item_type}` WHERE `name` like '%{标题前缀模式}%'"
)
```

**输出最终对照表：**

```
✅ PRD → User Story 同步完成

PRD：{local_path}（v{version}）
项目：{project}-{target_version}

| # | 标题 | Base record_id | 项目 work_item_id | 规划版本 | 节点开关 |
|---|------|---------------|-------------------|----------|----------|
| 1 | ... | recXXX | XXXXX | {项目}-{版本} ✓ | B/F/T ✓ |
| ... |

⚠️ 不一致项（若有）：
- ...

📌 后续提示：
- 受权限限制未自动开启的节点开关：{列出}
- 请到飞书项目手动勾选后再流转
```

**不一致项报错：** 如发现 Base 有 / 项目无（或反之），列出差异并询问用户处理方式。

---

## 常见问题（务必告知用户）

1. **去重确认**：PRD §5 功能清单中大需求常完整包含小需求验收标准，Step 3 务必先输出疑似父子覆盖列表请用户确认合并策略再创建。
2. **Base 表无 record-delete API**：去重时把多余记录的「目标版本」字段清空让其退出版本视图，**不实际删除记录**。
3. **「规划版本」字段权限**：飞书项目里通常需要先成为该工作项的「产品经理」才能编辑，必须先 5c 加角色，再 5d 写字段。
4. **节点开关权限**：部分开关（如「产品设计」）受角色权限限制，本 skill 默认只设置 `mapping.feishu_project.node_switches.default` 中列出的开关，其他让用户手动勾选。
5. **节点误流转无法回滚**：不要为了写字段而流转节点。所有字段均可在「需求创建」节点完成。
6. **`create_workitem` 时传规划版本字段静默失败**：API 不报错但实际为 null，必须创建后单独 `update_field` 设置。
7. **PRD status=draft 守门**：frontmatter.status 为 draft 或有未解决 OQ 时，Step 0.5 会要求用户确认是否继续，建议先用 prd-sync 完成评审再拆 Story。

## 权限

| 操作 | 所需 scope / 角色 |
|------|------------------|
| 飞书 Base 读写 | `bitable:app` |
| 飞书云文档读 | `docs:document:readonly` / `wiki:wiki:readonly` |
| 飞书项目工作项创建/更新 | 用户在飞书项目的对应空间内有需求创建权限 |
| 设置规划版本字段 | 必须为该工作项的「产品经理」角色 |

## 接入新项目

为新项目（如 CPQ、WLS）配置：

1. 编辑 [`references/template-mapping.md`](references/template-mapping.md) 的 `## PROJECTS` 段落，按现有 PST 实例的格式补一份新项目的实例
2. 必须填写：`base.app_token` / `base.table_id` / `base.fields.*` / `feishu_project.project_key` / `feishu_project.template_id` / `feishu_project.fields.*` / `feishu_project.roles.product_manager` / `feishu_project.node_switches.default` / `title_prefix_rules`
3. 用 `lark-cli base +field-list` 与 `mcp__FeishuProjectMcp__list_workitem_field_config` 查 ID
4. 完成后即可在 skill 调用时通过项目代号引用

## 参考

- [`references/userstoryrule.md`](references/userstoryrule.md) — User Story 通用书写规则
- [`references/template-mapping.md`](references/template-mapping.md) — 字段/角色/模板映射（通用契约 + 项目实例）
- [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md) — 认证与权限（必读）
- [`../lark-base/SKILL.md`](../lark-base/SKILL.md) — Base 表读写 `+record-search` / `+record-create` / `+record-update`
- [`../lark-doc/SKILL.md`](../lark-doc/SKILL.md) — 飞书云文档读取（PRD 在 wiki 中时）
- [`../write-a-prd/SKILL.md`](../write-a-prd/SKILL.md) — 上游：PRD 骨架生成
- [`../lark-workflow-prd-sync/SKILL.md`](../lark-workflow-prd-sync/SKILL.md) — 上游：PRD 同步维护
