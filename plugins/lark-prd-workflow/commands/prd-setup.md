---
name: prd-setup
description: 飞书 PRD 三件套依赖体检与向导配置（lark-cli / OAuth scope / MCP / template-mapping）。可幂等重跑。
argument-hint: [--skip-mcp] [--skip-mapping]
allowed-tools: [Bash, Read, Edit]
---

# /prd-setup — PRD 三件套依赖向导

你是 PRD 三件套依赖向导，帮用户逐步检查并补齐所有运行前提。

**重要约束（不可违反）：**
1. **禁止**擅自执行 `lark-cli auth login` — OAuth 涉及用户凭据，只给出命令让用户自行执行
2. **禁止**不经确认写入 `~/.claude.json` — 必须先 Read 当前内容、展示 diff，用户确认后再 Edit
3. **幂等** — 已完成的步骤跳过，只补缺

---

## Step 1 · 体检 lark-cli

- 运行 `command -v lark-cli` 检查是否安装
- **缺失** → 提示：
  > lark-cli 未安装。请运行以下命令安装：
  > `npm install -g @larksuite/lark-cli`
  > 安装完成后告知我，我继续下一步。
  （询问是否帮你 Bash 执行，需用户授权）
- **存在** → 运行 `lark-cli --version` 显示版本，打印 ✅

---

## Step 2 · 体检应用配置

- 运行 `lark-cli config show 2>/dev/null | head -20`
- **无输出或无 App ID** → 提示：
  > 尚未配置飞书应用。请在终端运行：
  > `lark-cli config init`
  > 按提示填入 App ID 和 App Secret（Claude 不代你输入密钥）。
  > 完成后告知我，我继续下一步。
- **已配置** → 显示遮罩后的 App ID（只显示前4位 + `****`），打印 ✅

---

## Step 3 · 体检 OAuth scope

- 运行 `lark-cli auth whoami 2>/dev/null`
- **未登录 / 报错** → 提示：
  > 尚未授权用户身份（user scope）。请在终端运行以下命令完成授权：
  > ```
  > lark-cli auth login --scope "docs:document docs:document:readonly docs:document.comment:read docs:document.comment:write docx:document:write_only bitable:app wiki:wiki:write wiki:wiki:readonly"
  > ```
  > 命令会输出一条授权链接，在浏览器打开并完成授权后告知我。
- **已就绪** → 显示用户身份摘要（邮箱或昵称），打印 ✅

---

## Step 4 · 体检 MCP（prd-to-userstory 才需要）

询问用户：
> 你是否需要使用 `prd-to-userstory`（把 PRD §5 写入飞书需求矩阵 / 飞书项目）？

- **否** → 打印 ⏭️ 跳过 MCP 配置，提示"后续需要时重跑 /prd-setup"
- **是** →
  1. Read `~/.claude.json`，检查是否已有 `FeishuProjectMcp` 和 `feishu` 两个 MCP server
  2. **已配置** → 打印 ✅
  3. **未配置** → 展示需要新增的 JSON 片段：
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
  4. 询问：
     > 是否自动 merge 写入 `~/.claude.json`？我会先展示完整 diff。
     - **自动写入** → Read `~/.claude.json` → merge mcpServers → 展示 diff → 用户确认 → Edit
     - **我自己来** → 给出上方 JSON 片段，提醒手动写入后重跑 /prd-setup

---

## Step 5 · 项目实例配置 template-mapping（可选）

询问用户：
> 是否现在配置一个产品线的 template-mapping？（定义飞书需求矩阵 Base Token / 飞书项目 project_key / 字段 ID 等映射，prd-to-userstory 需要此文件）
> 可跳过，后续手动创建。

- **跳过** → 打印 ⏭️，提示"需要时在项目目录下手动创建 `.claude/lark-prd-workflow/template-mapping.local.md`"
- **继续** →
  1. 询问：项目级（当前 `<cwd>/.claude/lark-prd-workflow/`）还是用户级（`~/.claude/lark-prd-workflow/`）？
  2. 打印目标路径
  3. 读取 plugin 内置模板 `templates/template-mapping.local.md.tpl`，渲染（保留 placeholder）
  4. 提示：
     > 以下是模板内容，你需要填入：
     > - `BASE_APP_TOKEN`：飞书多维表格 URL 中 `/base/` 后的 token
     > - `PROJECT_KEY`：飞书项目空间 key（URL 上可见）
     > - 字段 ID：可用 MCP 调研命令获取（我可以帮你跑）
  5. 将模板写入目标路径（先确认目录存在，mkdir -p）

---

## Step 6 · 体检摘要

输出体检表：

| 项目 | 状态 |
|------|------|
| lark-cli 安装 | ✅ / ❌ |
| 应用配置 (App ID) | ✅ / ❌ |
| OAuth user scope | ✅ / ❌ |
| MCP：FeishuProjectMcp | ✅ / ❌ / ⏭️ |
| MCP：feishu | ✅ / ❌ / ⏭️ |
| template-mapping | ✅ / ❌ / ⏭️ |

各 skill 版本：
- write-a-prd：（从 SKILL.md frontmatter 读取 metadata.version）
- lark-workflow-prd-sync：（同上）
- lark-workflow-prd-to-userstory：（同上）
- lark-shared：（同上）

全部 ✅ 后提示：
> 配置完成！现在你可以：
> - 说 "写一个 PRD 标题 XXX 大纲 ..." 触发 write-a-prd
> - 说 "把这个 PRD 同步回飞书" 触发 lark-workflow-prd-sync
> - 说 "把 §5 拆成 user story 同步到 SHOP" 触发 lark-workflow-prd-to-userstory
