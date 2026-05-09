---
name: lark-workflow-prd-to-userstory
description: "PRD 转 User Story 工作流：把 PRD 的功能清单生成 P0 User Story、写入飞书需求矩阵 Base 表，并同步到飞书项目对应版本中。当用户需要从 PRD 同步需求到飞书需求矩阵和飞书项目、prd-to-userstory、把功能清单转成 user story、按版本批量创建需求、对齐需求矩阵与需求管理时使用。"
metadata:
  author: 雪松-Ash Zeng
  version: 1.1.0
  requires:
    bins: ["lark-cli"]
    mcps: ["FeishuProjectMcp", "feishu"]
---

# PRD → User Story → 需求矩阵 → 飞书项目 工作流

**CRITICAL — 开始前 MUST 用 Read 工具读取以下文件：**

1. [`references/userstoryrule.md`](references/userstoryrule.md) — User Story 通用书写规则（INVEST、P0、格式约束、跨项目复用）
2. [`references/template-mapping.md`](references/template-mapping.md) — 字段/角色/模板映射的 **通用契约 + 项目实例**，每个项目首次接入时填好实例后即可使用
3. [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md) — lark-cli 认证与权限处理

> 本 skill 与具体产品线（PST / CPQ / WLS / 其他）解耦：通过 `template-mapping.md` 的「项目实例」段落注入差异，主流程不变。

## 适用场景

- "把 PRD 同步到需求矩阵和飞书项目"
- "从 PRD 的功能清单生成 user story"
- "按版本批量创建需求"
- "对齐 {项目} 需求矩阵 v{版本} 与飞书项目 {项目}-{版本}"

## 输入

| 参数 | 示例 | 说明 |
|------|------|------|
| **项目代号** | `PST` / `CPQ` / `WLS` 等 | 决定加载 `template-mapping.md` 中的哪个项目实例。无明显多产品线场景时可省略，skill 会读 mapping 文件里的 `default_project`。 |
| **PRD 版本号** | `26.5.1.0` | 飞书项目对应版本工作项需提前建好，名为 `{项目}-{版本号}`（也可在 mapping 中按项目重命名） |
| **PRD 来源** | 本地目录 `prd/2026/5/` 或飞书 wiki URL | 二选一；本地优先 |

如用户未提供任一必填项，**必用 AskUserQuestion** 询问，不要猜。

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
Step 0  加载项目实例配置（template-mapping.md 中的 PROJECTS[{项目}]）
        │
        ▼
Step 1  扫描 PRD 来源 ──► 让用户确认本次同步的 PRD 文件
        │
        ▼
Step 2  Read PRD ──► 提取 § 4 功能清单 + 引用的需求详细设计章节
        ├─ 按 mapping.title_prefix_rules 自动判别标题前缀
        ▼
Step 3  生成 P0 User Story 草稿（依据 references/userstoryrule.md）
        ├─ 父子去重：识别覆盖关系，AskUserQuestion 让用户确认合并策略
        ├─ 输出 markdown 预览表，用户确认后才进入 Step 4
        ▼
Step 4  写入需求矩阵 Base 表（mapping.base.*）
        ├─ +record-search 检查同名记录避免重复
        ├─ +record-create 批量创建（字段名按 mapping.base.fields 映射）
        ▼
Step 5  同步到飞书项目（mcp__FeishuProjectMcp__）
        ├─ 5a 验证版本工作项存在
        ├─ 5b 批量 create_workitem（template / 所属产品 / 优先级 / description）
        ├─ 5c 设置当前用户为产品经理（必须，否则 5d 无权写）
        ├─ 5d 设置规划版本字段
        ├─ 5e 勾选节点开关：mapping.feishu_project.node_switches.default
        ▼
Step 6  双向对齐核对 ──► 输出最终对照表
```

---

## Step 0：加载项目实例配置

按用户提供的「项目代号」从 [`references/template-mapping.md`](references/template-mapping.md) 中读取该项目的所有 ID 与字段映射，存入工作流上下文。后续 Step 1–6 全部用变量引用，不出现硬编码 ID。

如用户未给项目代号且 mapping 中只有一个项目实例，自动使用该实例；多于一个则用 AskUserQuestion 让用户选。

## Step 1：确定 PRD 文件

**本地目录：**

```bash
ls -1 {PRD目录}/*.md
```

列出后用 AskUserQuestion 让用户选择本次要处理的 PRD（可能多于 1 个）。单文件目录可直接进入 Step 2。

**飞书 wiki URL：** 用 `lark-cli docs +fetch --doc {URL} --doc-format markdown` 拉取到本地临时文件后再进入 Step 2。

## Step 2：解析 PRD

```
Read {PRD文件}
```

**提取目标：**

1. **§ 4 功能清单**（markdown 表格，列：功能模块 | 功能描述 | 优先级 | 开发状态 | 备注）
   - 只取 `优先级 = P0` 的行；其他丢弃
   - `备注` 列里的「需求详细设计 §xxx」用于回到 PRD 上文找对应详细章节，作为 user story 验收标准的素材
2. **§ 需求详细设计**（每条 P0 对应的子章节）

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

**用户确认门：** 输出预览表（标题 / 角色 / 价值 / 验收标准条数），等用户确认后才进入 Step 4。**不允许跳过这一步直接写入。**

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

**提取 PRD 飞书 wiki 链接：** PRD markdown 顶部一般有原始链接；若没有，用 `lark-cli docs +search --search-key "{PRD标题}"` 找。

记录每条创建后的 `record_id` 备 Step 6 核对。

## Step 5：同步到飞书项目

参考 `mapping.feishu_project` 段落。

### 5a 验证版本

```python
mcp__FeishuProjectMcp__get_workitem_brief(
  url="https://project.feishu.cn/{mapping.feishu_project.project_key}/version/detail/{version_id}"
)
# 用户口语版本号 26.5.1.0 → 完整名 {项目代号}-26.5.1.0；
# 若用户没给 version_id，让 ta 提供版本工作项 URL。
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

**输出对照表：**

| # | 标题 | Base record_id | 项目 work_item_id | 规划版本 | 节点开关 |
|---|------|---------------|-------------------|----------|----------|
| 1 | ... | recXXX | XXXXX | {项目}-{版本} ✓ | B/F/T ✓ |

**不一致项报错：** 如发现 Base 有 / 项目无（或反之），列出差异并询问用户处理方式。

---

## 常见问题（务必告知用户）

1. **去重确认**：PRD 功能清单中大需求常完整包含小需求验收标准，Step 3 务必先输出疑似父子覆盖列表请用户确认合并策略再创建。
2. **Base 表无 record-delete API**：去重时把多余记录的「目标版本」字段清空让其退出版本视图，**不实际删除记录**。
3. **「规划版本」字段权限**：飞书项目里通常需要先成为该工作项的「产品经理」才能编辑，必须先 5c 加角色，再 5d 写字段。
4. **节点开关权限**：部分开关（如「产品设计」）受角色权限限制，本 skill 默认只设置 `mapping.feishu_project.node_switches.default` 中列出的开关，其他让用户手动勾选。
5. **节点误流转无法回滚**：不要为了写字段而流转节点。所有字段均可在「需求创建」节点完成。
6. **`create_workitem` 时传规划版本字段静默失败**：API 不报错但实际为 null，必须创建后单独 `update_field` 设置。

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
