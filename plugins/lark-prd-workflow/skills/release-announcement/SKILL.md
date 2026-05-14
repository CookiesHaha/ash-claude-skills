---
name: release-announcement
description: "发版公告自动生成：从 PRD 飞书文档提取更新内容，生成三个版本的发版公告（简略版、详细中文版、详细英文版），并创建为飞书云文档（用户名下）。当用户需要生成发版公告、版本发布说明、release notes、发版简报时使用。"
metadata:
  author: 雪松-Ash Zeng
  version: 1.0.0
  requires:
    bins: ["lark-cli"]
---

# 发版公告自动生成工作流

**CRITICAL — 开始前 MUST 用 Read 工具读取以下文件：**

1. [`references/announcement-templates.md`](references/announcement-templates.md) — 三版公告模板、书写规则与文件命名规范
2. [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md) — lark-cli 认证与权限处理

---

## 适用场景

- "生成发版公告"
- "从 PRD 生成 release notes"
- "发版简报 / 发版说明"
- "release-announcement {PRD链接} {版本号}"

## 输入

| 参数 | 示例 | 说明 |
|------|------|------|
| **PRD 来源** | 飞书 wiki URL 或 doc_token | PRD 文档地址（必填） |
| **版本号** | `v1.2.0` | 发版版本号（必填） |
| **发版日期** | `2026年5月13日` | 可选，默认取当天 |
| **产品名** | `MyApp` | 可选，默认从 PRD 标题提取 |
| **产品全称** | `我的产品（MyApp）` | 可选，默认从 PRD 标题提取 |

**输入示例：**

```
/release-announcement
PRD: https://your-company.feishu.cn/wiki/XXXXXXXXXXXXX
版本号: v1.2.0
```

## 前置条件

```bash
# 飞书云文档（user 身份）— 用于读取 PRD 和创建公告文档
lark-cli auth login --domain docs,drive,wiki
```

## 工作流

```
{PRD 来源, 版本号, [发版日期], [产品名]}
        │
        ▼
Step 0  认证检查 ──► 确认 lark-cli user 身份可用
        │
        ▼
Step 1  获取 PRD 内容
        ├─ wiki URL → lark-cli wiki +get-node → doc_token
        ├─ lark-cli docs +fetch --as user --doc-format markdown → PRD 正文
        ▼
Step 2  分析 PRD ──► 提取更新内容
        ├─ 识别功能模块（参考 PRD 中的章节划分）
        ├─ 按模块分组，P0 需求优先
        ├─ 提取核心价值方向（3个）
        ▼
Step 3  生成三版公告（按 references/announcement-templates.md）
        ├─ 简略版（日期 + 版本号 + 3要点摘要）
        ├─ 详细中文版（价值总览 + 分模块详述）
        ├─ 详细英文版（对应英文翻译）
        ├─ 输出预览，用户确认后进入 Step 4
        ▼
Step 4  创建飞书文档（×3）
        ├─ lark-cli docs +create --as user（关键：用户名下）
        ├─ 记录每个文档的 URL 和 doc_token
        ▼
Step 5  输出结果 + [HANDOFF] 块
```

---

## Step 0：认证检查

确认 lark-cli user 身份可用于读写飞书文档：

```bash
lark-cli auth status
```

若未认证或 scope 不足，按 `lark-shared/SKILL.md` 引导用户完成授权：

```bash
lark-cli auth login --domain docs,drive,wiki
```

## Step 1：获取 PRD 内容

### 1a. 从 wiki URL 解析 doc_token

若用户提供的是飞书 wiki URL（如 `https://your-company.feishu.cn/wiki/XXXXX`）：

```bash
lark-cli wiki +get-node --as user --node-token {wiki_token}
```

从返回中提取 `obj_token`（即 doc_token）。

### 1b. 拉取 PRD 正文

```bash
lark-cli docs +fetch --as user \
  --api-version v2 \
  --doc "{doc_token}" \
  --doc-format markdown
```

返回 PRD 的 Markdown 全文。若内容过长，重点关注：
- **需求详细设计章节** — 各功能模块的详细描述
- **功能清单章节** — P0 功能条目列表
- **整体说明章节** — 整体变更概要

## Step 2：分析 PRD 内容

从 PRD 中提取以下信息：

1. **核心价值方向**（3个）— 用于价值总览段落
2. **功能模块分组** — 按产品模块（参考 PRD 中的章节划分）归类
3. **每个功能点的详细描述** — 从需求详细设计章节提取
4. **新增功能标记** — 全新功能标注「新增」
5. **Bug 修复** — 单独归类
6. **进行中的功能** — 标注「正在努力中」

**提取原则：**
- P0 需求全部纳入
- 按用户可感知的功能价值组织，而非按开发任务
- 技术细节转化为用户可理解的功能描述
- 保留关键参数和规则（如标准编号、阈值、默认值等）

## Step 3：生成三版公告

按 [`references/announcement-templates.md`](references/announcement-templates.md) 中的模板与规则生成：

1. **简略版** — 日期 + 版本号 + 3 要点摘要，使用飞书高亮块
2. **详细中文版** — 价值总览 + 分模块详述
3. **详细英文版** — 与中文版结构对齐，使用英文

### 用户确认门

**必须输出三版公告预览，等用户确认后才进入 Step 4。不允许跳过这一步直接创建文档。**

```
[CHECKPOINT: release-announcement Step 3 → Step 4]

PRD 来源：{PRD URL}
产品：{产品名}  版本号：{版本号}  发版日期：{日期}

已生成三版公告：
1. 简略版 — {核心要点数}条要点，{字数}字
2. 详细中文版 — {模块数}个功能模块，{功能点数}个功能点
3. 详细英文版 — 与中文版结构对齐

请审阅以上内容，确认后回复「继续」创建飞书文档；需要调整请指出具体位置。
```

## Step 4：创建飞书文档

**CRITICAL：必须使用 `--as user` 确保文档创建在用户名下，而非 bot 名下。**

文件命名规范见 [`references/announcement-templates.md § 4`](references/announcement-templates.md)。

将公告内容写入临时文件，然后调用 lark-cli 创建：

```bash
# 简略版
lark-cli docs +create --as user \
  --api-version v2 \
  --doc-format markdown \
  --file-name "{简略版文件名}" \
  --content "$(cat /tmp/release_brief.md)"

# 详细中文版
lark-cli docs +create --as user \
  --api-version v2 \
  --doc-format markdown \
  --file-name "{中文版文件名}" \
  --content "$(cat /tmp/release_cn.md)"

# 详细英文版
lark-cli docs +create --as user \
  --api-version v2 \
  --doc-format markdown \
  --file-name "{英文版文件名}" \
  --content "$(cat /tmp/release_en.md)"
```

**注意事项：**
- 内容中的特殊字符需转义（引号、反引号等）
- 若内容过长导致命令行参数超限，先 Write 到临时文件再用 `$(cat ...)` 读取
- 每次创建后记录返回的 `url` 和 `document_id`

## Step 5：输出结果

```
✅ 发版公告已生成

📋 简略版：{简略版飞书URL}
📄 详细中文版：{中文版飞书URL}
📄 详细英文版：{英文版飞书URL}

版本：{版本号}
发版日期：{日期}
PRD 来源：{PRD URL}

[HANDOFF: release-announcement]
- product: {产品名}
- version: {版本号}
- release_date: {发版日期}
- prd_source: {PRD URL}
- brief_url: {简略版飞书URL}
- brief_doc_token: {简略版doc_token}
- cn_url: {中文版飞书URL}
- cn_doc_token: {中文版doc_token}
- en_url: {英文版飞书URL}
- en_doc_token: {英文版doc_token}
```

---

## 规则

1. **用户名下创建** — 所有飞书文档必须使用 `lark-cli docs +create --as user` 创建，绝不使用 MCP bot 身份或 `--as bot`。这是硬性安全约束。
2. **内容准确** — 公告内容必须忠实于 PRD，不臆造功能、不夸大描述。PRD 未提及的功能不允许出现在公告中。
3. **三版对齐** — 简略版是详细版的摘要，详细英文版与详细中文版结构对齐。三版公告的功能覆盖范围必须一致。
4. **用户确认门** — Step 3 生成公告后必须让用户审阅确认，不允许直接跳到 Step 4 创建文档。
5. **文件名 ≤ 27 字符** — 飞书文档名有字符长度限制，命名时需检查（规则见 references）。
6. **P0 优先** — 公告优先展示 P0（最高优先级）需求；非紧急需求可简化描述或归入「正在努力中」。
7. **No implementation** — 本 skill 只产出发版公告文档，不涉及任何代码。
8. **术语一致** — 中英文版术语翻译必须与 PRD 中已有的英文表述保持一致。

## 常见问题

1. **认证失败 / Permission denied**：运行 `lark-cli auth login --domain docs,drive,wiki` 重新授权。详见 `lark-shared/SKILL.md`。
2. **wiki URL 无法解析**：确认 URL 格式为 `https://{domain}.feishu.cn/wiki/{node_token}`，先用 `lark-cli wiki +get-node` 获取 doc_token。
3. **文件名超长**：缩短版本号（如 `v1.2.3.4` → `v1.2.3`）或缩短产品名。
4. **内容超长导致命令行报错**：将内容写入 `/tmp/` 临时文件，用 `$(cat /tmp/xxx.md)` 传入。
5. **文档创建在 bot 名下**：检查命令是否包含 `--as user`。若遗漏，已创建的文档需手动授权或重新创建。
6. **PRD 内容不完整**：若 PRD 缺少需求详细设计或功能清单章节，在公告中标注「详情见 PRD」并告知用户补充。

## 权限

| 操作 | 所需 scope |
|------|-----------|
| 读取 PRD 云文档 | `docs:document:readonly` |
| 读取 wiki 节点 | `wiki:wiki:readonly` |
| 创建飞书云文档 | `docs:document` |
| 文件上传/管理 | `drive:drive` |

## 参考

- [`references/announcement-templates.md`](references/announcement-templates.md) — 三版公告模板、书写规则与文件命名规范
- [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md) — lark-cli 认证与权限
- [`../write-a-prd/SKILL.md`](../write-a-prd/SKILL.md) — PRD 结构参考
- [`../lark-doc/SKILL.md`](../lark-doc/SKILL.md) — docs +create / +fetch
