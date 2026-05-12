# Changelog — lark-prd-workflow

## [1.1.0] — 2026-05-12

### 变更
- 向导命令重命名：`/prd-setup` → `/lark-prd-workflow-setup`（避免多 plugin 命名冲突）
- 修复 OAuth scope：Step 3 使用正确的飞书细粒度 scope 名称（原 `docs:document` 等不存在的名称已替换）
- Step 3 新增 token refresh 场景识别：若 `lark-cli auth status` 显示 `needs_refresh` 则只刷新，不重授权 scope
- `plugin.json` 新增 `defaultPrompt`：安装后自动提示运行 `/lark-prd-workflow-setup`

## [1.0.0] — 2026-05-12

### 初始发布
- 封装 write-a-prd v3.0.0
- 封装 lark-workflow-prd-sync v2.0.0
- 封装 lark-workflow-prd-to-userstory v2.0.0
- 内置 lark-shared v1.0.0
- 新增 /prd-setup 向导（lark-cli 体检、OAuth scope、MCP 配置、template-mapping 初始化）
