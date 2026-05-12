# lark-prd-workflow

飞书 PRD 三件套 Claude Code Plugin：`write-a-prd` → `lark-workflow-prd-sync` → `lark-workflow-prd-to-userstory`

## 安装

```bash
/plugin marketplace add https://github.com/CookiesHaha/ash-claude-skills.git
/plugin install lark-prd-workflow@ash-claude-marketplace
/lark-prd-workflow-setup
```

## 使用

- `"写一个 PRD 标题 XXX 大纲 ..."` → 触发 write-a-prd
- `"把这个 PRD 同步回飞书"` → 触发 lark-workflow-prd-sync
- `"把 §5 拆成 user story 同步到 SHOP"` → 触发 lark-workflow-prd-to-userstory
- `/lark-prd-workflow-setup` → 向导式依赖体检与配置（可幂等重跑）

## 升级

```bash
/plugin marketplace update ash-claude-marketplace
/plugin upgrade lark-prd-workflow
```
