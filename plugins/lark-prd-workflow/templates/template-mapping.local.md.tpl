---
# template-mapping.local.md
# 本文件为项目实例配置，gitignore，不提交到版本库
# 由 /lark-prd-workflow-setup Step 5 生成，或手动创建
# 读取优先级：项目级 (.claude/lark-prd-workflow/) > 用户级 (~/.claude/lark-prd-workflow/) > plugin 内置 fallback
---

# 产品线标识（自定义，用于日志和提示）
PRODUCT_LINE: "{{PRODUCT_LINE}}"

# 飞书需求矩阵 Base App Token
# 获取方式：打开飞书多维表格，URL 中 /base/ 后的字符串
BASE_APP_TOKEN: "{{BASE_APP_TOKEN}}"

# 飞书需求矩阵 User Story 表 table_id
# 获取方式：/lark-prd-workflow-setup 可代跑 lark-cli 查询，或在 Base 设置中查看
USERSTORY_TABLE_ID: "{{USERSTORY_TABLE_ID}}"

# 飞书项目空间 project_key
# 获取方式：飞书项目 URL 中 project_ 开头的字段
PROJECT_KEY: "{{PROJECT_KEY}}"

# User Story 字段 ID 映射
# 获取方式：/lark-prd-workflow-setup 可代跑 MCP 调研命令填充
FIELD_MAPPING:
  title: "{{FIELD_ID_TITLE}}"
  description: "{{FIELD_ID_DESCRIPTION}}"
  priority: "{{FIELD_ID_PRIORITY}}"
  version: "{{FIELD_ID_VERSION}}"
  product_line: "{{FIELD_ID_PRODUCT_LINE}}"
