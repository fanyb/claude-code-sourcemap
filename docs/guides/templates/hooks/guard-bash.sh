#!/bin/bash
# guard-bash.sh
# 拦截高危 Shell 命令
# 放到工作区 .claude/hooks/guard-bash.sh，并 chmod +x

set -euo pipefail

payload=$(cat)
cmd=$(echo "$payload" | jq -r '.tool_input.command // empty')

# 黑名单（按需扩展）
BLOCKED_PATTERNS=(
  'mvn deploy'
  'git push'
  'git push --force'
  'git reset --hard'
  'kubectl'
  'helm'
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \*'
  'mysql.*sit'
  'curl.*prod'
  'docker push'
  'terraform apply'
)

for pat in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$cmd" | grep -qE "\b$pat"; then
    cat >&2 <<EOF
🚨 命令被拦截：$cmd
匹配规则：$pat

这类操作必须手动执行，不能由 Claude 自动触发。
如果确实需要，请你本人在另一个终端执行。
EOF
    exit 2
  fi
done

exit 0
