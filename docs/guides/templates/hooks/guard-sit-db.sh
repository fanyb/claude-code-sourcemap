#!/bin/bash
# guard-sit-db.sh
# 禁止写入任何 SIT 数据库连接配置
# 放到工作区 .claude/hooks/guard-sit-db.sh，并 chmod +x

set -euo pipefail

payload=$(cat)
content=$(echo "$payload" | jq -r '.tool_input.new_string // .tool_input.content // empty')
file_path=$(echo "$payload" | jq -r '.tool_input.file_path // empty')

# 禁止写入包含 SIT 数据库连接字符串的配置
if echo "$content" | grep -qE 'jdbc:mysql://.*sit|sit-db|\.sit\.|application-sit'; then
  cat >&2 <<EOF
🚨 禁止写入 SIT 数据库配置。
文件：$file_path

测试必须走：
  - 单元测试：H2 或 Mockito mock
  - 集成测试：Testcontainers 本地拉 MySQL 容器
  - 不允许直接连 SIT 数据库

如果你确实在合法修改配置文件（不是测试），
请人工执行，不要通过 Claude 自动写入。
EOF
  exit 2
fi

exit 0
