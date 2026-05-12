# lark-prd-workflow

飞书 PRD 三件套 Claude Code Plugin，覆盖**从功能大纲到飞书项目工作项**的完整链路：

```
write-a-prd  →  lark-workflow-prd-sync  →  lark-workflow-prd-to-userstory
  ✍️ 创建骨架        🔄 飞书 ↔ 本地同步          📋 PRD → User Story → 飞书项目
```

## 前置条件

### 1. lark-cli（必装）

```bash
npm install -g @larksuite/lark-cli
lark-cli --version
lark-cli config init   # 填入飞书自建应用 App ID / Secret
lark-cli auth login --scope "docs:document docs:document:readonly docs:document.comment:read docs:document.comment:write docx:document:write_only bitable:app wiki:wiki:write wiki:wiki:readonly"
```

### 2. 飞书项目 MCP（仅 prd-to-userstory 需要）

在 `~/.claude.json` 或项目 `.mcp.json` 中添加：

```json
{
  "mcpServers": {
    "FeishuProjectMcp": { "command": "npx", "args": ["-y", "@feishu-project/mcp-server"] },
    "feishu":           { "command": "npx", "args": ["-y", "@larksuite/feishu-mcp"] }
  }
}
```

重启 Claude Code 后输入 `/mcp` 验证工具列表已加载。

## 安装

```bash
# 1. 添加 marketplace（已添加可跳过）
/plugin marketplace add https://git.hairoutech.com/ash.zeng/ash-claude-skills

# 2. 安装 plugin
/plugin install lark-prd-workflow@ash-claude-marketplace

# 3. 运行向导（配置 lark-cli / OAuth / MCP / template-mapping）
/lark-prd-workflow-setup
```

## 使用

| 说什么 | 触发的技能 |
|--------|-----------|
| `写一个 PRD 标题 XXX 大纲 ...` | `write-a-prd` |
| `把这个 PRD 同步回飞书` | `lark-workflow-prd-sync` |
| `把 §5 拆成 user story 同步到飞书项目` | `lark-workflow-prd-to-userstory` |
| `/lark-prd-workflow-setup` | 向导式依赖体检与配置（可幂等重跑） |

三个技能均**独立可用**；串联时通过 PRD 顶部 YAML frontmatter 与 `[HANDOFF]` 块自动传递上下文。

## 升级

```bash
/plugin marketplace update ash-claude-marketplace
/plugin upgrade lark-prd-workflow
```

## 项目实例配置（仅 prd-to-userstory 需要）

`lark-workflow-prd-to-userstory` 通过 `template-mapping.md` 解耦产品线 ID。运行 `/lark-prd-workflow-setup` 后，按提示填写：

- 飞书需求矩阵 Base App Token / User Story 表 table_id
- 飞书项目 project_key
- User Story 字段 / 角色 ID 映射

配置文件保存在项目 `.claude/lark-prd-workflow/template-mapping.local.md`（已 gitignore）。

## PRD 章节约定

| 编号 | 章节 | 谁写 | 谁读 |
|------|------|------|------|
| frontmatter | YAML 元数据 | write-a-prd 生成 / prd-sync 维护 | 三件套共用 |
| §1 版本信息 | 版本号 / 创建日期 / 审核人 | write-a-prd | prd-sync 维护 |
| §2 变更日志 | 每次大/小版本一行 | prd-sync | — |
| §3 整体说明 | §3.1 整体变更 / §3.2 范围说明 | prd-sync 从 §4 自动生成 | — |
| **§4 需求详细设计** | **核心创作区**（`##` 模块 + `###` 子项） | **用户主笔** | prd-sync **不覆盖** |
| §5 功能清单 | 模块 / 描述 / P0 / 待开发 / 备注 | prd-sync 自动生成 | prd-to-userstory 解析 |
| §6 Open Questions | 评论锚定的待澄清问题 | prd-sync 维护 | 评审用 |
| §7 附录 | 参考文档 / 术语表 | 用户 | — |

> **关键约束**：prd-sync 严禁覆盖 §4，只增量更新 §3.1 / §5 / §6 / §2。

## 更新日志

见 [CHANGELOG.md](CHANGELOG.md)。
