# ash-claude-skills

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-2.1+-purple.svg)](https://docs.anthropic.com/en/docs/claude-code)

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) Skills for **PRD 三件套工作流**（PRD authoring → bi-directional sync → User Story pipeline）on [Lark / 飞书](https://www.larksuite.com/).

> **作者：** 雪松-Ash Zeng · **License：** MIT

---

## 🎯 PRD 三件套（PRD Trilogy）

三个 Skill 互相独立又串联，覆盖**从功能大纲到飞书项目工作项**的完整链路：

```
┌──────────────────┐    ┌────────────────────┐    ┌─────────────────────────────┐
│  write-a-prd     │ →  │  prd-sync          │ →  │  prd-to-userstory           │
│  ✍️ 创建 PRD 骨架  │    │  🔄 飞书 ↔ 本地同步   │    │  📋 PRD → User Story         │
│                  │    │                    │    │     → 需求矩阵 → 飞书项目      │
└──────────────────┘    └────────────────────┘    └─────────────────────────────┘
        ↓                       ↓                              ↓
   生成本地 .md +          下载飞书 PRD +               读 §5 功能清单 +
   飞书云文档骨架           整理评论为 OQ +              生成 P0 User Story +
   YAML frontmatter       增量同步回飞书                写 Base 表 + 飞书项目
```

每个 Skill **均可单独使用**；串联使用时通过 PRD 顶部 YAML frontmatter 与 `[HANDOFF]` 块自动传递上下文，无需重复输入项目代号 / 版本号。

| Skill | 作用 | 触发关键词 |
|-------|------|-----------|
| [`write-a-prd`](skills/write-a-prd/) | 从功能大纲生成本地 Markdown PRD + 飞书云文档骨架，按统一章节规范（§1–§7）输出。 | `写 PRD` / `创建 PRD 初稿` / `write-a-prd` / `起草产品需求文档` |
| [`lark-workflow-prd-sync`](skills/lark-workflow-prd-sync/) | 飞书 ↔ 本地双向同步：下载 PRD、整理评论为 Open Questions、依据 §4 详细设计回填 §3.1 整体变更与 §5 功能清单、增量同步（不覆盖 §4）。支持评论解决状态识别、版本号自动维护。 | `prd sync` / `prd 同步` / `从飞书下载 PRD` / `更新 PRD` |
| [`lark-workflow-prd-to-userstory`](skills/lark-workflow-prd-to-userstory/) | PRD §5 功能清单 → P0 User Story → 飞书需求矩阵 Base 表 → 飞书项目对应版本工作项。通过 `template-mapping.md` 解耦多产品线。 | `prd to userstory` / `prd 转需求` / `按版本批量创建需求` |

---

## 📦 前置条件

### 1. lark-cli（必装）

[lark-cli](https://github.com/larksuite/lark-cli) 是飞书官方 CLI，提供云文档 / Base / 评论 / Wiki 等原子能力。所有三个 Skill 都依赖它。

```bash
# 安装（npm 全局）
npm install -g @larksuite/lark-cli

# 验证
lark-cli --version
```

#### 首次配置

```bash
# 1) 初始化应用配置（按提示填入飞书自建应用的 App ID / Secret）
lark-cli config init

# 2) 登录用户身份（OAuth）
#    PRD 三件套至少需要以下 scope：
lark-cli auth login --scope "docs:document docs:document:readonly docs:document.comment:read docs:document.comment:write docx:document:write_only bitable:app wiki:wiki:write wiki:wiki:readonly"
```

> **scope 是增量授权的**：多次 `auth login --scope "..."` 会把新 scope 累积到现有 token，无需重新授权已有 scope。

如果你已经使用 [`lark-shared`](https://github.com/larksuite/lark-skills) skill，跳过本节即可。

### 2. 飞书项目 MCP（仅 prd-to-userstory 需要）

`lark-workflow-prd-to-userstory` 在 Step 5 同步到飞书项目时使用 [Feishu Project MCP](https://project.feishu.cn/) 的 MCP server，需要在 Claude Code 的 MCP 配置中加上：

```json
{
  "mcpServers": {
    "FeishuProjectMcp": {
      "command": "npx",
      "args": ["-y", "@feishu-project/mcp-server"]
    },
    "feishu": {
      "command": "npx",
      "args": ["-y", "@larksuite/feishu-mcp"]
    }
  }
}
```

放在 `~/.claude.json`（全局）或 `<project>/.mcp.json`（项目级）。重启 Claude Code 后输入 `/mcp` 验证 `mcp__FeishuProjectMcp__*` / `mcp__feishu__*` 工具列表已加载。

> 仅需要 PRD 创建/同步功能时（write-a-prd + prd-sync），可跳过 MCP 配置。

### 3. Claude Code

- **Claude Code** ≥ 2.1.x
- 推荐启用 Skills（在 [Settings → Skills](https://docs.anthropic.com/en/docs/claude-code/skills) 中打开）

---

## 🚀 安装

### 方式 1：克隆到全局 skills 目录（推荐）

```bash
cd ~/.claude/skills/
git clone https://github.com/CookiesHaha/ash-claude-skills.git _ash-prd
ln -s _ash-prd/skills/write-a-prd .
ln -s _ash-prd/skills/lark-workflow-prd-sync .
ln -s _ash-prd/skills/lark-workflow-prd-to-userstory .
```

### 方式 2：克隆到项目级 skills 目录

```bash
cd <你的项目>/.claude/skills/
git clone https://github.com/CookiesHaha/ash-claude-skills.git _ash-prd
ln -s _ash-prd/skills/write-a-prd .
ln -s _ash-prd/skills/lark-workflow-prd-sync .
ln -s _ash-prd/skills/lark-workflow-prd-to-userstory .
```

### 验证

打开 Claude Code，在新会话中输入 `/skills`（或在系统 reminder 中查看），应能看到三个 Skill：
- `write-a-prd`
- `lark-workflow-prd-sync`
- `lark-workflow-prd-to-userstory`

---

## 🧭 典型用法

### 场景 A：从零开始写一个新 PRD

```
我（用户）：写一个 PRD，标题"商家后台批量导出订单"，目标版本 v1.2.0，项目 SHOP
- 订单列表勾选导出
- 单次导出上限 10000 条
- 权限校验

Claude → 触发 write-a-prd
  → 生成 prd/2026/5/shop-batch-export-prd.md
  → 创建飞书云文档（自动 fill feishu_url / feishu_doc_token 到 frontmatter）
  → 输出 [HANDOFF] 块

我：好的，把它同步回飞书

Claude → 触发 prd-sync
  → 读取 frontmatter 拿到 feishu_url
  → 拉评论、维护 OQ、增量同步
  → 输出 [HANDOFF: prd-sync → prd-to-userstory]

我：把 §5 功能清单拆成 user story 同步到 SHOP 项目 v1.2.0

Claude → 触发 prd-to-userstory
  → 从 [HANDOFF] / frontmatter 自动读 project=SHOP, target_version=v1.2.0
  → Step 3 输出 checkpoint 表，等我确认
  → 写 Base 表 → 写飞书项目 → 输出最终对照表
```

### 场景 B：手头已有飞书 PRD，整理后转 Story

```
我：把这个飞书文档同步到本地并整理评论
   https://xxx.feishu.cn/wiki/abc123

Claude → 触发 prd-sync
  → 下载 → 补 frontmatter → 整理 OQ → 同步回飞书
  → 输出 [HANDOFF]

我：拆 user story 写到飞书项目
Claude → 触发 prd-to-userstory（自动读取 [HANDOFF]）
```

### 场景 C：单独使用任一 Skill

每个 Skill 都向下兼容：
- 没有 frontmatter 的旧版 PRD（带 `<!-- 飞书文档：URL -->` 注释）—— prd-sync 自动识别并补写 frontmatter
- 完全手写的 PRD（只要遵守 §5 功能清单格式）—— prd-to-userstory 可以直接拆 Story

---

## ⚙️ 配置项目实例（仅 `lark-workflow-prd-to-userstory`）

`lark-workflow-prd-to-userstory` 通过 [`references/template-mapping.md`](skills/lark-workflow-prd-to-userstory/references/template-mapping.md) 把主流程与产品线 ID 解耦。仓库中只提供**通用契约（§1）**与**新项目模板（§2.1）**——你需要：

1. 复制 `references/template-mapping.md` 中 `### 2.1 新项目模板` 的 yaml 块
2. 按 `§ 3 调研指引` 收集你自己的 Base App Token / 飞书项目 project_key / 字段 ID / 角色 ID
3. 把填好的实例放到 `references/template-mapping.local.md`（已加入 `.gitignore`，不会被误提交），或放进你私有的 fork / 分支

调研指引里的命令参考：

```bash
# Base 表字段列表
lark-cli base +field-list --app-token <token> --table-id <id>
```

```python
# 飞书项目工作项字段配置（拿 field_xxx）
mcp__FeishuProjectMcp__list_workitem_field_config(
  project_key="<key>", work_item_type="story", page_num=1
)

# 工作项角色配置（拿 role_xxx）
mcp__FeishuProjectMcp__list_workitem_role_config(
  project_key="<key>", work_item_type="story", page_num=1
)
```

---

## 📐 PRD 章节约定

三件套共享同一份 PRD 章节规范（见 [`skills/write-a-prd/prd-template.md`](skills/write-a-prd/prd-template.md)）：

| 编号 | 章节 | 谁写 | 谁读 |
|------|------|------|------|
| `frontmatter` | YAML 元数据 | write-a-prd 生成 / prd-sync 维护 | 三件套共用 |
| `§1` 版本信息 | 版本号 / 创建日期 / 审核人 | write-a-prd | prd-sync 维护 |
| `§2` 变更日志 | 每次大/小版本一行 | prd-sync | — |
| `§3` 整体说明 | `§3.1 整体变更` / `§3.2 范围说明` | prd-sync 从 §4 自动生成 | — |
| `§4` 需求详细设计 | **核心创作区**（`##` 模块 + `###` 子项） | 用户主笔 | prd-sync **不覆盖** |
| `§5` 功能清单 | `功能模块 / 描述 / P0 / 待开发 / 备注` 表格 | prd-sync 自动生成 | prd-to-userstory 解析 |
| `§6` Open Questions | 评论锚定的待澄清问题 | prd-sync 维护 | 评审用 |
| `§7` 附录 | 参考文档 / 术语表 | 用户 | — |

> **关键约束**：prd-sync 严禁覆盖 §4（用户的核心创作区），只增量更新 §3.1 / §5 / §6 / §2。

---

## 🔗 Skill 之间的交接协议

每个 Skill 完成后会输出标准化的 `[HANDOFF]` 块，下一个 Skill 自动读取：

```
[HANDOFF: write-a-prd → prd-sync]
- local_path: prd/2026/5/xxx-prd.md
- feishu_url: https://xxx.feishu.cn/wiki/xxx
- feishu_doc_token: xxx
- version: 1.0
- status: draft
- feature_count: 7
- open_questions: 0
- project: SHOP
- target_version: v1.2.0
```

```
[HANDOFF: prd-sync → prd-to-userstory]
- local_path: prd/2026/5/xxx-prd.md
- feishu_url: https://xxx.feishu.cn/wiki/xxx
- version: 1.2
- status: reviewing | approved
- feature_count: 7
- unresolved_oq: 1
- project: SHOP
- target_version: v1.2.0
```

---

## 🛠 故障排查

| 现象 | 可能原因 | 解决 |
|------|---------|------|
| `lark-cli` 报 Permission denied | 缺 scope | `lark-cli auth login --scope "<缺失的 scope>"`（增量授权） |
| `mcp__FeishuProjectMcp__*` 工具不可见 | MCP 未配置 / 未重启 | 检查 `.mcp.json`，重启 Claude Code 后输入 `/mcp` |
| 同步回飞书后 §4 内容被清空 | 误用了 `--command overwrite` | prd-sync 严禁 overwrite，必须用 `block_replace`；见 SKILL.md Step 6 |
| 飞书项目报"无权编辑 规划版本" | 当前用户不是工作项的「产品经理」 | prd-to-userstory Step 5c 会自动加角色，请勿跳过 |
| 创建工作项时 target_version 字段静默失败 | 飞书项目 API 限制 | 必须创建后单独 `update_field` 设置（Step 5d 已处理） |

---

## 🤝 贡献

欢迎 PR / Issue。新增 skill 请遵循以下约定：

- skill 目录放在 `skills/<skill-name>/`，至少包含 `SKILL.md`
- **不在 `SKILL.md` 或 `references/` 中包含任何企业内部 ID**（app_token、project_key、field_xxx、role_xxx 等真实值）
- 内部专用配置一律走 `*.local.md` 并依赖 [`.gitignore`](.gitignore)
- SKILL.md 顶部的 `description` 字段要明确触发关键词，避免与已有 skill 冲突

---

## 📄 License

[MIT](LICENSE)
