# claude-skills

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) Skills focused on **PRD authoring & sync workflows** with [Lark / 飞书](https://www.larksuite.com/).

> **作者：** 雪松-Ash Zeng · **License：** MIT

## Skills

| Skill | 作用 | 触发关键词 |
|-------|------|-----------|
| [`lark-workflow-prd-sync`](skills/lark-workflow-prd-sync/) | PRD 文档双向同步：从飞书下载 PRD → 本地 `.md` 落盘 → 提取评论为 Open Questions → 依据 §3 需求详细设计更新 §1.2 整体变更与 §4 功能清单 → 增量同步回飞书。支持评论解决状态识别、版本号自动维护。 | `prd sync` / `prd 同步` / `从飞书下载 PRD` / `更新 PRD` |
| [`lark-workflow-prd-to-userstory`](skills/lark-workflow-prd-to-userstory/) | PRD → User Story 流水线：把 PRD §4 功能清单生成 P0 User Story、写入飞书需求矩阵 Base 表、并同步到飞书项目对应版本中。通过 `template-mapping.md` 解耦多产品线。 | `prd to userstory` / `prd 转需求` / `按版本批量创建需求` |

## 安装

### 方式 1：克隆到项目级 skills 目录

```bash
cd <你的项目>/.claude/skills/
git clone https://github.com/<your-org>/claude-skills.git _claude-skills
ln -s _claude-skills/skills/lark-workflow-prd-sync .
ln -s _claude-skills/skills/lark-workflow-prd-to-userstory .
```

### 方式 2：克隆到全局 skills 目录

```bash
cd ~/.claude/skills/
git clone https://github.com/<your-org>/claude-skills.git _claude-skills
ln -s _claude-skills/skills/lark-workflow-prd-sync .
ln -s _claude-skills/skills/lark-workflow-prd-to-userstory .
```

## 依赖

- **[lark-cli](https://github.com/larksuite/lark-cli)** — 飞书官方 CLI（云文档 / Base / 评论 / 项目等原子能力）
- **MCPs**：`FeishuProjectMcp`、`feishu`（部分能力依赖）
- **Claude Code** ≥ 2.1.x

首次使用前，先按 [`lark-shared`](https://github.com/larksuite/lark-skills) skill 完成 `lark-cli config init` 与 `lark-cli auth login`。

## 配置项目实例（仅 `lark-workflow-prd-to-userstory`）

`lark-workflow-prd-to-userstory` 通过 `references/template-mapping.md` 把主流程与产品线 ID 解耦。仓库中只提供**通用契约**与**新项目模板**——你需要：

1. 复制 `references/template-mapping.md` 中 `### 2.1 新项目模板` 的 yaml 块
2. 按 `§ 3 调研指引` 收集你自己的 Base App Token / 飞书项目 project_key / 字段 ID / 角色 ID
3. 把填好的实例放到 `references/template-mapping.local.md`（已加入 `.gitignore`，不会被误提交），或放进你的私有 fork

## 贡献

欢迎 PR / Issue。新增 skill 请遵循以下约定：

- skill 目录放在 `skills/<skill-name>/`，至少包含 `SKILL.md`
- 不在 `SKILL.md` 或 `references/` 中包含任何企业内部 ID（app_token、project_key、field_xxx、role_xxx 等真实值）
- 内部专用配置一律走 `*.local.md` 并依赖 `.gitignore`

## License

[MIT](LICENSE)
