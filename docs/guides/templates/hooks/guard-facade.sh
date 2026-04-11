#!/bin/bash
# guard-facade.sh
# 拦截对 Dubbo Facade 接口文件的直接修改
# 放到工作区 .claude/hooks/guard-facade.sh，并 chmod +x

set -euo pipefail

payload=$(cat)
file_path=$(echo "$payload" | jq -r '.tool_input.file_path // empty')

# 命中 Facade 文件时强制提醒
if [[ "$file_path" == *"/api/"*"Facade.java" ]] || [[ "$file_path" == *"Facade.java" && "$file_path" == *"/api/"* ]]; then
  cat >&2 <<'EOF'
🚨 检测到修改 Dubbo Facade 接口。

必须先跑 /impact 确认影响面：
  /impact <FacadeName>.<methodName>

规则：
  1. 禁止修改任何已存在方法的签名
  2. 需要变更时，新增 methodV2 并给老方法加 @Deprecated
  3. 确认无下游 consumer 时才能直接改（必须在 PR 描述里写明）

如果已经完成影响分析，请在对话里回复：已完成影响分析，允许修改。
EOF
  exit 2
fi

exit 0
