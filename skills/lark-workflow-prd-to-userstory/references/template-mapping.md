# 字段 / 角色 / 模板映射

**用途：** 把 SKILL.md 主流程与各产品线（PST / CPQ / WLS / 其他）的具体 ID 解耦。本文件分两部分：

1. **§ 1 通用契约（Schema）**：描述 skill 主流程**需要哪些信息**，与具体项目无关。新接入的项目按此契约填写实例。
2. **§ 2 项目实例（PROJECTS）**：每个产品线一份实例，存放真实的 ID / 字段名 / 选项值。

> **维护原则：** 通用契约保持稳定，不随项目变化；项目实例可独立增删。

---

## § 1 通用契约（Schema）

每个项目实例必须按下表提供完整字段。所有字段在 SKILL.md 中通过 `{mapping.<path>}` 引用。

### 1.1 顶层字段

| Schema 字段 | 说明 | 必填 |
|-------------|------|----|
| `code` | 项目代号（如 `PST` / `CPQ` / `WLS`），与用户口语一致 | ✅ |
| `display_name` | 项目显示名（如「PST 售前工具」） | ✅ |
| `default` | 是否作为缺省项目（`true`/`false`，全局只能有一个） | ✅ |
| `version_name_format` | 版本工作项命名格式，如 `{code}-{version}` 或 `{code} v{version}`，用于反查 | ✅ |
| `target_version_value_format` | Base 表「目标版本」字段写入格式，如 `v{version}` 或 `{code}-{version}` | ✅ |
| `title_prefix_rules` | 标题前缀判别规则（见 § 1.4） | ✅ |
| `default_demand_category` | 无法判别时的「需求类别」缺省值 | ✅ |
| `base` | Base 表配置（见 § 1.2） | ✅ |
| `feishu_project` | 飞书项目配置（见 § 1.3） | ✅ |

### 1.2 Base 表配置（`base`）

| Schema 字段 | 说明 |
|-------------|------|
| `app_token` | Base App Token（URL 中 `/base/<token>` 部分） |
| `table_id` | 数据表 ID（URL 中 `?table=<id>` 部分） |
| `default_view_id` | 默认视图 ID（按版本筛选用） |
| `fields.title` | Base 中「标题」字段名 |
| `fields.description` | Base 中「描述」字段名 |
| `fields.epic` | Base 中「Epic」字段名（SingleSelect） |
| `fields.type` | Base 中「类型」字段名（SingleSelect） |
| `fields.priority` | Base 中「优先级」字段名（SingleSelect） |
| `fields.task_type` | Base 中「任务类型」字段名（SingleSelect） |
| `fields.demand_type` | Base 中「需求类型」字段名（SingleSelect） |
| `fields.demand_category` | Base 中「需求类别」字段名（SingleSelect） |
| `fields.target_version` | Base 中「预计落地版本/目标版本」字段名（SingleSelect） |
| `fields.link` | Base 中「PRD 链接/附件」字段名（URL） |
| `option_values.type_userstory` | 「类型」字段中代表 UserStory 的选项值 |
| `option_values.priority_p0` | 「优先级」字段中代表 P0 的选项值 |
| `option_values.task_type_product` | 「任务类型」字段中代表「产品需求」的选项值 |
| `option_values.demand_type_default` | 「需求类型」字段缺省值（如「常规需求」） |
| `epic_options[]` | 全部 Epic 选项值列表（用于 AskUserQuestion 让用户选） |

### 1.3 飞书项目配置（`feishu_project`）

| Schema 字段 | 说明 |
|-------------|------|
| `project_key` | 项目空间 key（URL 中 `project.feishu.cn/<key>/`，也是 simple_name） |
| `space_id` | 完整空间 ID（用于 MQL 跨空间引用） |
| `work_item_type` | 工作项类型 key（如 `story`） |
| `template_id` | 默认使用的工作流模板 ID |
| `template_name` | 模板名（注释用） |
| `fields.product` | 「所属产品」字段 key |
| `fields.target_version` | 「规划版本/目标版本」字段 key（**注意：创建时无效，必须创建后单独 update**） |
| `fields.target_quarter` | 「规划季度」字段 key（可选） |
| `fields.complexity` | 「复杂度」字段 key（可选） |
| `option_values.product` | 所属产品的 option_id |
| `priority_options.urgent` | 优先级=紧急的 option_id |
| `priority_options.high` | 优先级=高的 option_id |
| `priority_options.medium` | 优先级=中的 option_id |
| `priority_options.low` | 优先级=低的 option_id |
| `roles.product_manager` | 「产品经理」角色 key（**关键：缺它无法编辑 target_version**） |
| `roles.creator` | 「创建人」角色 key |
| `roles.product_se` | 「产品 SE」角色 key（可选） |
| `roles.backend` | 「后端开发」角色 key（可选） |
| `roles.frontend` | 「前端开发」角色 key（可选） |
| `roles.qa` | 「功能测试」角色 key（可选） |
| `node_switches.default[]` | 默认开启的节点开关字段 key 列表（如 `[功能测试, 后端开发, 前端开发]`） |
| `node_switches.restricted[]` | 受角色权限限制不自动开启的开关 key 列表（如 `[产品设计]`，提示用户手动开） |
| `version_id_lookup` | 版本号 → 版本工作项 ID 的速查表（按需追加） |

### 1.4 标题前缀判别规则（`title_prefix_rules`）

数组，每条规则按顺序匹配，命中即返回对应前缀；全部不命中则用 AskUserQuestion 让用户选。

| Schema 字段 | 说明 |
|-------------|------|
| `match_field` | 匹配字段：`prd_title` / `prd_filename` / `prd_section_demand_category` |
| `keywords[]` | 关键词数组，命中其一即触发 |
| `prefix` | 输出的标题前缀文本（如 `【PST-优化需求】`） |
| `demand_category` | 联动写入 Base 的「需求类别」值（如 `优化需求`） |

---

## § 2 项目实例（PROJECTS）

> **注意：** 项目实例包含 Base App Token、飞书项目 project_key、字段/角色 ID 等敏感配置，
> 不在开源仓库中提供。请按 § 2.1 「新项目模板」复制一份并填入你自己的真实 ID 后使用。
>
> 建议把填好的实例放在 `references/template-mapping.local.md`（已加入 `.gitignore`），
> 或放在你私有的 fork / 分支里。

### 2.1 新项目模板（复制后填入）

```yaml
code: <PROJECT_CODE>
display_name: <显示名>
default: false
version_name_format: "{code}-{version}"
target_version_value_format: "v{version}"
default_demand_category: <默认需求类别>

title_prefix_rules:
  - match_field: prd_title
    keywords: [<关键词>]
    prefix: 【<前缀>】
    demand_category: <类别>

base:
  app_token: <App Token>
  table_id: <Table ID>
  default_view_id: <View ID>
  fields:
    title: <标题字段名>
    description: <描述字段名>
    epic: <Epic 字段名>
    type: <类型字段名>
    priority: <优先级字段名>
    task_type: <任务类型字段名>
    demand_type: <需求类型字段名>
    demand_category: <需求类别字段名>
    target_version: <目标版本字段名>
    link: <链接字段名>
  option_values:
    type_userstory: <选项值>
    priority_p0: <选项值>
    task_type_product: <选项值>
    demand_type_default: <选项值>
  epic_options: [<选项1>, <选项2>]

feishu_project:
  project_key: <项目 key>
  space_id: <空间 ID>
  work_item_type: <工作项类型>
  template_id: <模板 ID>
  template_name: <模板名>
  fields:
    product: <field_xxx>
    target_version: <field_xxx>
  option_values:
    product: <option_id>
  priority_options:
    urgent: <option_id>
  roles:
    product_manager: <role_xxx>     # 必填，否则无法写 target_version
  node_switches:
    default: [<field_xxx>, <field_xxx>]
    restricted: [<field_xxx>]
  version_id_lookup: {}
```

---

## § 3 调研指引（接入新项目时）

按以下顺序调研并填入项目实例：

```bash
# 1. 找到 Base 表 app_token / table_id / view_id
#    打开 Base URL，从 /base/<token> 与 ?table=<id>&view=<view> 中提取

# 2. 列出 Base 字段名与选项值
lark-cli base +field-list --app-token <token> --table-id <id>

# 3. 查飞书项目空间 key
#    打开飞书项目 URL，project.feishu.cn/<key>/ 即 project_key
```

```python
# 4. 列出飞书项目模板列表（拿 template_id）
mcp__FeishuProjectMcp__list_workitem_field_config(
  project_key="<key>", work_item_type="story",
  field_keys=["template"], page_num=1
)

# 5. 列出工作项的字段配置（拿所有 field_key）
mcp__FeishuProjectMcp__list_workitem_field_config(
  project_key="<key>", work_item_type="story", page_num=1
)

# 6. 列出工作项的角色配置（拿 role_key）
mcp__FeishuProjectMcp__list_workitem_role_config(
  project_key="<key>", work_item_type="story", page_num=1
)

# 7. 找控制流程节点显示的 bool 开关字段
mcp__FeishuProjectMcp__list_workitem_field_config(
  project_key="<key>", work_item_type="story",
  field_types=["bool"], page_num=1
)
# 关注 field_desc 含「控制流程节点【XXX】显示与否」的字段

# 8. 反查版本工作项 ID
mcp__FeishuProjectMcp__get_workitem_brief(
  url="https://project.feishu.cn/<key>/version/detail/<version_id>"
)
```

完成调研后填入 § 2 对应项目实例即可。

---

## § 4 已知限制（所有项目通用）

| 限制 | 影响 | 应对 |
|------|------|------|
| Base 表 OpenAPI 不支持 record-delete | 重复记录无法直接删除 | 把目标版本字段清空，让记录退出版本视图 |
| 规划版本字段创建时静默失败 | 创建后字段为 null | 必须创建后单独 `update_field` 设置 |
| 规划版本字段需特定角色才能编辑 | 报「无权编辑」 | 先把当前用户加为「产品经理」角色，再写字段 |
| 部分节点开关字段需角色才能编辑 | 报「无权编辑」 | 写到 `node_switches.restricted`，提示用户在 UI 手动勾选 |
| 节点流转后无法回滚（doing 状态） | `transition_node action=rollback` 报错 | 不要为了写字段而误流转节点；所有字段均可在「需求创建」节点完成 |
