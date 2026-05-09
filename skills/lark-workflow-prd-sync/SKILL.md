---
name: lark-workflow-prd-sync
description: "PRD 文档工作流：从飞书下载 PRD → 本地 .md 落盘 → 提取评论为 Open Questions → 依据 §3 需求详细设计更新 §1.2 整体变更与 §4 功能清单 → 将三个章节增量同步回飞书（严禁覆盖 §3 需求详细设计）。支持增量同步：识别评论 is_solved 状态，删除本地已解决评论标记并更新 OQ 状态；按变更大小自动维护版本号（小版本 +0.1 / 大版本 +1.0）。触发关键词：prd sync / prd同步 / 从飞书下载PRD / 更新PRD"
metadata:
  author: 雪松-Ash Zeng
  version: 1.1.0
  changelog: |
    1.1.0 (2026-05-09)
      - 修正 `drive file.comments list` 命令参数为 `--params` 形式（CLI 实际签名）
      - 新增 Step 2.3：处理已解决评论（删除本地 ⚠️ [评论] 标记 + 更新 OQ 状态为「已解决」）
      - 新增 Step 0：版本号自动维护规则（小版本/大版本判断）
      - 新增 Step 6.0：通过 `--scope section --start-block-id` 精准获取表格 block ID
      - block_replace 时使用 stdin (`--content -`) 而非文件路径，规避 lark-cli 的相对路径限制
    1.0.0 - 初版
  requires:
    bins: ["lark-cli"]
---

# PRD 文档工作流

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`~/.claude/skills/lark-shared/SKILL.md`](/Users/ash/.claude/skills/lark-shared/SKILL.md)，其中包含认证、权限处理**

## 适用场景

- "帮我从飞书下载这个 PRD 并整理好"
- "把飞书文档里的评论整理成 Open Questions"
- "根据详细设计更新整体变更和功能清单"
- "把本地改好的 PRD 同步回飞书"
- "prd sync" / "prd同步"

## 所需 OAuth Scopes（user 身份）

```bash
# 读取文档
lark-cli auth login --scope "docx:document:readonly"

# 读取评论
lark-cli auth login --scope "docs:document.comment:read"

# 更新文档（同步回飞书时）
lark-cli auth login --scope "docx:document:write_only docx:document:readonly"
```

> **说明**：多次 login 的 scope 会累积（增量授权），无需重复授权已有 scope。

---

## Step 0：版本号自动维护规则

每次同步前先识别「本次变更规模」，按下表自动维护本地 PRD 顶部的「版本信息」与「变更日志」表：

| 变更规模 | 版本号增长 | 判定标准 |
|---|---|---|
| **大版本（major）** | `1.x → 2.0` | §3 详细设计大幅重写、§4 功能清单新增/删除 ≥ 5 行、整体方案换路 |
| **小版本（minor）** | `1.0 → 1.1` | 局部章节微调、零散字段更新、评论解决/补充、OQ 状态变化、版本日志补登 |

**操作清单：**

1. 在「版本信息」表的版本号字段更新为新版本号
2. 在「变更日志」表追加一行新记录（时间、版本号、变更人、主要变更内容）
3. 同步飞书时也要替换飞书侧的「变更日志」表（用 block_replace）

---

## 完整工作流

```
飞书文档 URL
    │
    ▼
Step 1: 下载文档 → 保存 .md 到 prd/YYYY/M/
    │
    ▼
Step 2: 拉取所有评论
    ├─► 2.1 未解决评论 → 写入/更新 §5 Open Questions
    └─► 2.2 已解决评论 → 删除本地 ⚠️ [评论] 标记 + 更新 OQ 状态为「已解决」
    │
    ▼
Step 3: 分析 §3 需求详细设计
    │
    ├─► 更新 §1.2 整体变更（每条需求对应一行）
    └─► 更新 §4 功能清单（每个功能点对应一行）
    │
    ▼
Step 4: 如有未解决 OQ → 在文档标题末尾追加 -draft
    │
    ▼
Step 5: 按 Step 0 规则更新版本号 + 变更日志
    │
    ▼
Step 6: 增量同步回飞书（只更新 §1.2 / §4 / §5 / 变更日志，不触碰 §3）
```

---

## Step 1：下载文档并保存为本地 .md

### 1.1 提取文档 token

从 URL 中提取 token：
- `https://xxx.feishu.cn/docx/TOKEN` → token = `TOKEN`
- `https://xxx.feishu.cn/wiki/NODE_TOKEN` → 需先解析真实 doc token（见下方）

```bash
# wiki 链接需先获取真实 doc token
lark-cli wiki +get-node --node-token NODE_TOKEN --as user
# 从返回的 obj_token 字段获取真实文档 token
```

### 1.2 下载文档内容

```bash
lark-cli docs +fetch --api-version v2 \
  --doc "DOC_TOKEN" \
  --doc-format markdown \
  --as user
```

### 1.3 保存路径规则

- 目标目录：`prd/YYYY/M/`（如 `prd/2026/5/`）
- 文件名：用文档标题转换（中文空格替换为连字符，小写英文）
- 示例：`hps-x-v2-selection-prd.md`

> **操作**：将 `docs +fetch` 的输出写入对应路径文件。

---

## Step 2：提取飞书评论 → §5 Open Questions

### 2.1 获取所有评论（含已解决和未解决）

⚠️ **CLI 实际参数签名**：`drive file.comments list` 使用 `--params` 传 JSON，**不是** `--doc-token`/`--file-type`。

```bash
lark-cli drive file.comments list \
  --params '{"file_token":"DOC_TOKEN","file_type":"docx"}' \
  --as user --page-all \
  -q '[.data.items[] | {comment_id, is_solved, quote, replies: [.reply_list.replies[].content.elements[] | (.text_run.content // "")] | join("")}]'
```

返回字段说明：

| 字段 | 说明 |
|------|------|
| `comment_id` | 评论 ID |
| `is_solved` | `true` = 已解决（用户在飞书已标记为解决）；`false` = 未解决（需在 OQ 表呈现） |
| `quote` | 评论锚定的原文片段（用于定位章节） |
| `reply_list.replies[].content.elements[].text_run.content` | 评论正文 |

### 2.2 未解决评论 → §5 Open Questions 表

只处理 `is_solved: false` 的评论，按下表结构写入：

```markdown
| 编号 | 所在章节 | 问题描述 | 负责人 | 状态 |
| --- | --- | --- | --- | --- |
| OQ-01 | §3.X ... | [评论内容] | TBD | 未解决 |
```

定位章节：根据 `quote` 在本地 .md 中 grep 匹配最近的标题（`## / ###`）。

### 2.3 已解决评论 → 删除本地评论标记 + 更新 OQ 状态

对所有 `is_solved: true` 的评论：

1. **本地正文清理**：删除该 quote 附近的 `> ⚠️ **[评论]** ...` 行（评论标记已不再有效）
2. **OQ 表状态更新**：在 §5 表中找到对应行，将「状态」列从「未解决」改为「已解决」（保留行而不是删除，便于追踪历史）
3. **同步飞书 §3 增量内容**：飞书侧 §3 章节可能因评论解决而被作者补充了新内容（如新增公式、删除字段等），需要将这些增量同步到本地 §3、§1.2、§4

> 提示：判断飞书侧 §3 是否有更新，可对比 Step 1 下载的最新 markdown 与本地 §3 段落，diff 出新增/修改的关键决策。

---

## Step 3：依据 §3 更新 §1.2 整体变更

### 表格结构

```markdown
## 1.2 整体变更

| 需求背景 | 处理方式 | 变更类型 |
| --- | --- | --- |
| [原始问题/痛点] | [解决方案] | 新增 / 优化 / 修复 |
```

### 分析规则

遍历 §3 的每一个子章节（`### 3.X.X`），提取：
- **需求背景**：该章节描述的问题/背景
- **处理方式**：该章节的具体改动方案（参数变化、逻辑更新、新增功能等）
- **变更类型**：`新增`（全新功能） / `优化`（已有功能改进） / `修复`（缺陷修正）

每个子章节对应 §1.2 中的一行，一一对应，不要合并。

---

## Step 4：依据 §3 更新 §4 功能清单

### 表格结构

```markdown
# 4. 功能清单

| 功能模块 | 功能描述 | 优先级 | 开发状态 | 备注 |
| --- | --- | --- | --- | --- |
| [模块名] | [具体功能] | P0 | 待开发 | §3.X.X，[待确认项] |
```

### 分析规则

**粒度原则：`## ` 级别的章节 = 一条功能清单行（User Story 粒度），不要按子章节拆分。**

- **功能模块**：对应的系统模块或功能域名称（来自章节标题提炼）
- **功能描述**：将整个章节的目标浓缩为一句话（动词开头，涵盖关键子项但不逐一列举），如"新增 / 更新 / 删除 / 禁用"
- **优先级**：默认 P0（主线功能）
- **开发状态**：默认"待开发"
- **备注**：标注来源章节标题 + 任何待确认的技术细节（来自评论或 TBD 标记）

> 子章节（`### ` 级别）的细节作为功能描述的补充说明写在同一行，不单独拆行。

---

## Step 5：-draft 标记规则

若 §5 Open Questions 表格中存在任意一行状态为 `未解决`，则在文档**标题行**（第一个 `# ` 开头的标题）末尾追加 `-draft`：

```markdown
# PRD：XXX-draft
```

若所有 OQ 均已解决，移除 `-draft` 后缀。

---

## Step 6：增量同步回飞书

### ⚠️ 核心约束：严禁整体覆盖

**禁止使用 `--command overwrite`**，因为会清空图片、评论和 §3 详细设计内容。
必须使用 **逐章节精确替换**。

### 6.0 推荐替换粒度：表格级 block_replace

实践证明，PRD 文档的 §1.2 / §4 / §5 / 变更日志 都是单一 `<table>` block，最佳做法是直接替换整个表格 block，而不是替换 heading + 表格。这样：
- 不会动到标题层级（避免破坏目录）
- 一个 block_id 一次替换，操作最少
- 表格 ID 唯一，定位精确

### 6.1 获取目标表格的 block ID

需要使用 `--scope section --start-block-id <heading_id>` 模式，先用 keyword 找到 heading ID，再用 section 模式拉取 heading 子树（含表格）：

```bash
# Step 1: 用 keyword 找到 heading 的 block ID
lark-cli docs +fetch --api-version v2 \
  --doc "DOC_TOKEN" \
  --detail with-ids \
  --scope keyword \
  --keyword "整体变更" \
  --as user
# 返回 <h3 id="HEADING_ID">1.2 整体变更</h3>

# Step 2: 用 section 模式拉取 heading 子树（含表格 ID）
lark-cli docs +fetch --api-version v2 \
  --doc "DOC_TOKEN" \
  --detail with-ids \
  --scope section \
  --start-block-id "HEADING_ID" \
  --as user
# 返回 <h3>...</h3><table id="TABLE_BLOCK_ID">...</table>
```

对 §1.2 / §4 / §5 / 变更日志 各重复一次（关键词分别用「整体变更」「功能清单」「Open Questions」「变更日志」）。

> **注意**：变更日志原文是 `<p><b>变更日志</b></p>`，section 模式默认只返回 heading 自身。需要加 `--scope range --start-block-id <heading_id> --context-after 2` 才能拿到后续表格 block。

### 6.2 用 stdin 喂 XML 内容做 block_replace

⚠️ **lark-cli 限制**：`--content @文件` 只支持当前目录的相对路径，不支持 `/tmp/xxx.xml`。改用 `--content -` 走 stdin 输入：

```bash
# 1. 把表格 XML 写到临时文件（不带外层 heading，只 <table>...</table>）
cat > /tmp/section_1_2_table.xml <<'EOF'
<table>
<colgroup>...</colgroup>
<thead>...</thead>
<tbody>...</tbody>
</table>
EOF

# 2. 通过 stdin 喂给 lark-cli
lark-cli docs +update --api-version v2 \
  --doc "DOC_TOKEN" \
  --command block_replace \
  --block-id "TABLE_BLOCK_ID" \
  --content - --as user < /tmp/section_1_2_table.xml
```

返回体出现 `"warnings": []` 就说明替换成功。

### 6.3 备选方案：str_replace + markdown 省略号语法

若无法精确获取 block ID，可使用 markdown 模式的 `str_replace`：

```bash
lark-cli docs +update --api-version v2 \
  --doc "DOC_TOKEN" \
  --command str_replace \
  --doc-format markdown \
  --pattern "## 1.2 整体变更...## 1.3" \
  --content - <<'EOF'
## 1.2 整体变更

| 需求背景 | 处理方式 | 变更类型 |
| --- | --- | --- |
| ... |

## 1.3
EOF
```

> **注意**：`...` 省略号语法会将从前缀到后缀的所有内容（含两端）整体替换为 `--content`，所以 content 中必须包含前缀和后缀。

---

## 权限速查表

| 操作 | CLI 命令 | 所需 Scope |
|------|----------|-----------|
| 读文档 | `docs +fetch` | `docx:document:readonly` |
| 读评论 | `drive file.comments list` | `docs:document.comment:read` |
| 改文档 | `docs +update` | `docx:document:write_only docx:document:readonly` |

---

## 参考

- [`~/.claude/skills/lark-shared/SKILL.md`](/Users/ash/.claude/skills/lark-shared/SKILL.md) — 认证、权限处理（必读）
- [`~/.claude/skills/lark-doc/references/lark-doc-update.md`](/Users/ash/.claude/skills/lark-doc/references/lark-doc-update.md) — `docs +update` 详细用法
- [`~/.claude/skills/lark-doc/references/lark-doc-fetch.md`](/Users/ash/.claude/skills/lark-doc/references/lark-doc-fetch.md) — `docs +fetch` 局部读取策略
- [`~/.claude/skills/lark-drive/SKILL.md`](/Users/ash/.claude/skills/lark-drive/SKILL.md) — `drive file.comments list` 用法
