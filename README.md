# ash-claude-skills

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-2.1+-purple.svg)](https://docs.anthropic.com/en/docs/claude-code)

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) Plugins and Skills for **PRD 三件套工作流**（PRD authoring → bi-directional sync → User Story pipeline）on [Lark / 飞书](https://www.larksuite.com/).

> **作者：** 雪松-Ash Zeng · **License：** MIT

---

## 🎯 PRD 三件套（PRD Trilogy）

三个技能互相独立又串联，覆盖**从功能大纲到飞书项目工作项**的完整链路：

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

| 技能 | 作用 | 触发关键词 |
|------|------|-----------|
| `write-a-prd` | 从功能大纲生成本地 Markdown PRD + 飞书云文档骨架，按统一章节规范（§1–§7）输出。 | `写 PRD` / `创建 PRD 初稿` / `write-a-prd` |
| `lark-workflow-prd-sync` | 飞书 ↔ 本地双向同步：下载 PRD、整理评论为 Open Questions、依据 §4 详细设计回填 §3.1 整体变更与 §5 功能清单、增量同步（不覆盖 §4）。 | `prd sync` / `prd 同步` / `从飞书下载 PRD` |
| `lark-workflow-prd-to-userstory` | PRD §5 功能清单 → P0 User Story → 飞书需求矩阵 Base 表 → 飞书项目对应版本工作项。 | `prd to userstory` / `prd 转需求` / `按版本批量创建需求` |

---

## 📦 前置条件

### 1. lark-cli（必装）

```bash
npm install -g @larksuite/lark-cli
lark-cli --version
lark-cli config init
lark-cli auth login --scope "docs:document docs:document:readonly docs:document.comment:read docs:document.comment:write docx:document:write_only bitable:app wiki:wiki:write wiki:wiki:readonly"
```

> scope 是增量授权的：多次 `auth login --scope "..."` 会把新 scope 累积到现有 token，无需重新授权已有 scope。

### 2. 飞书项目 MCP（仅 prd-to-userstory 需要）

在 `~/.claude.json`（全局）或 `<project>/.mcp.json`（项目级）中添加：

```json
{
  "mcpServers": {
    "FeishuProjectMcp": { "command": "npx", "args": ["-y", "@feishu-project/mcp-server"] },
    "feishu":           { "command": "npx", "args": ["-y", "@larksuite/feishu-mcp"] }
  }
}
```

重启 Claude Code 后输入 `/mcp` 验证 `mcp__FeishuProjectMcp__*` / `mcp__feishu__*` 工具列表已加载。

### 3. Claude Code ≥ 2.1.x

---

## 🚀 安装

### Plugin 方式（推荐）

```bash
# 1. 添加 marketplace（已添加可跳过）
/plugin marketplace add https://github.com/CookiesHaha/ash-claude-skills

# 2. 安装 plugin
/plugin install lark-prd-workflow@ash-claude-skills

# 3. 运行向导：体检 lark-cli / OAuth scope / MCP / template-mapping
/lark-prd-workflow-setup
```

安装后 Claude Code 会自动提示运行 `/lark-prd-workflow-setup`。

### 升级

```bash
/plugin marketplace update ash-claude-skills
/plugin upgrade lark-prd-workflow
```

---

## 🧭 典型用法

### 场景 A：从零开始写一个新 PRD

```
我：写一个 PRD，标题"商家后台批量导出订单"，目标版本 v1.2.0，项目 SHOP
- 订单列表勾选导出
- 单次导出上限 10000 条
- 权限校验

Claude → 触发 write-a-prd
  → 生成 prd/2026/5/shop-batch-export-prd.md（只有标题架子，§4 内容留空）
  → 创建飞书云文档（自动回填 feishu_url / feishu_doc_token 到 frontmatter）
  → 输出 [HANDOFF] 块

我：好的，把它同步回飞书

Claude → 触发 prd-sync
  → 读取 frontmatter 拿到 feishu_url → 拉评论、维护 OQ、增量同步

我：把 §5 功能清单拆成 user story 同步到 SHOP 项目 v1.2.0

Claude → 触发 prd-to-userstory
  → 从 [HANDOFF] / frontmatter 自动读 project=SHOP, target_version=v1.2.0
  → 写 Base 表 → 写飞书项目 → 输出最终对照表
```

### 场景 B：手头已有飞书 PRD，整理后转 Story

```
我：把这个飞书文档同步到本地并整理评论
   https://xxx.feishu.cn/wiki/abc123

Claude → 触发 prd-sync → 下载 → 补 frontmatter → 整理 OQ → 同步回飞书

我：拆 user story 写到飞书项目
Claude → 触发 prd-to-userstory（自动读取 [HANDOFF]）
```

---

## ⚙️ 配置项目实例（仅 prd-to-userstory 需要）

运行 `/lark-prd-workflow-setup` 后，按提示填入：

- 飞书需求矩阵 Base App Token / User Story 表 table_id
- 飞书项目 project_key
- User Story 字段 ID / 角色 ID 映射

配置保存在项目 `.claude/lark-prd-workflow/template-mapping.local.md`（已 gitignore）。

---

## 📐 PRD 章节约定

| 编号 | 章节 | 谁写 | 谁读 |
|------|------|------|------|
| `frontmatter` | YAML 元数据 | write-a-prd 生成 / prd-sync 维护 | 三件套共用 |
| `§1` 版本信息 | 版本号 / 创建日期 / 审核人 | write-a-prd | prd-sync 维护 |
| `§2` 变更日志 | 每次大/小版本一行 | prd-sync | — |
| `§3` 整体说明 | `§3.1 整体变更` / `§3.2 范围说明` | prd-sync 从 §4 自动生成 | — |
| **`§4` 需求详细设计** | **核心创作区**（`##` 模块 + `###` 子项） | **用户主笔** | prd-sync **不覆盖** |
| `§5` 功能清单 | `功能模块 / 描述 / P0 / 待开发 / 备注` 表格 | prd-sync 自动生成 | prd-to-userstory 解析 |
| `§6` Open Questions | 评论锚定的待澄清问题 | prd-sync 维护 | 评审用 |
| `§7` 附录 | 参考文档 / 术语表 | 用户 | — |

> **关键约束**：prd-sync 严禁覆盖 §4（用户的核心创作区），只增量更新 §3.1 / §5 / §6 / §2。

---

## 🔗 技能间交接协议

每个技能完成后输出标准化 `[HANDOFF]` 块，下一个技能自动读取：

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

---

## 🛠 故障排查

| 现象 | 可能原因 | 解决 |
|------|---------|------|
| `lark-cli` 报 Permission denied | 缺 scope | `lark-cli auth login --scope "<缺失的 scope>"` |
| `mcp__FeishuProjectMcp__*` 工具不可见 | MCP 未配置 / 未重启 | 检查 `.mcp.json`，重启后输入 `/mcp` |
| 同步回飞书后 §4 内容被清空 | 误用了 overwrite 模式 | prd-sync 必须用 `block_replace`，见 SKILL.md Step 6 |
| 飞书项目报"无权编辑规划版本" | 当前用户不是工作项「产品经理」 | prd-to-userstory Step 5c 会自动加角色，勿跳过 |
| `Unknown skill: lark-prd-workflow:xxx` | plugin 缓存版本过旧 | `/plugin upgrade lark-prd-workflow` |

---

## 🤝 贡献

欢迎 PR / Issue。新增 skill 请遵循：

- skill 目录放在 `plugins/<plugin-name>/skills/<skill-name>/`
- **不在 `SKILL.md` 或 `references/` 中包含任何企业内部 ID**（app_token、project_key、field_xxx 等真实值）
- 内部配置一律走 `*.local.md` 并依赖 `.gitignore`
- SKILL.md 顶部 `description` 字段要明确触发关键词，避免与已有 skill 冲突

---

## 📄 License

[MIT](LICENSE)

---

## 旧版安装方式（Deprecated）

> ⚠️ 以下 clone + symlink 方式已弃用，推荐改用 Plugin 方式（见上方安装步骤）。

```bash
cd ~/.claude/skills/
git clone https://github.com/CookiesHaha/ash-claude-skills.git _ash-prd
ln -s _ash-prd/skills/write-a-prd .
ln -s _ash-prd/skills/lark-workflow-prd-sync .
ln -s _ash-prd/skills/lark-workflow-prd-to-userstory .
```

### 从旧版迁移到 Plugin

```bash
# 1. 删除旧 symlink（不删源文件）
rm -f ~/.claude/skills/write-a-prd
rm -f ~/.claude/skills/lark-workflow-prd-sync
rm -f ~/.claude/skills/lark-workflow-prd-to-userstory
rm -f ~/.claude/skills/lark-shared

# 2. 安装 Plugin
/plugin marketplace add https://github.com/CookiesHaha/ash-claude-skills
/plugin install lark-prd-workflow@ash-claude-skills

# 3. 重跑向导
/lark-prd-workflow-setup
```
