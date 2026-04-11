#!/bin/bash
# format-and-lint.sh
# Edit/Write 之后自动 format + lint
# 放到工作区 .claude/hooks/format-and-lint.sh，并 chmod +x

set -euo pipefail

payload=$(cat)
file_path=$(echo "$payload" | jq -r '.tool_input.file_path // empty')

# 文件不存在就跳过
[ -f "$file_path" ] || exit 0

# 找到该文件所在的 git 仓库根目录
repo_root=$(cd "$(dirname "$file_path")" && git rev-parse --show-toplevel 2>/dev/null || echo "")

if [ -z "$repo_root" ]; then
  exit 0
fi

case "$file_path" in
  *.java)
    # Java 文件：跑 maven spotless（如果项目有配置）
    if grep -q "spotless" "$repo_root/pom.xml" 2>/dev/null; then
      (cd "$repo_root" && mvn spotless:apply -q 2>&1 | tail -20) || true
    fi
    ;;

  *.ts|*.tsx)
    # TS 文件：eslint --fix + 类型检查
    if [ -f "$repo_root/package.json" ]; then
      (cd "$repo_root" && npx --no-install eslint --fix "$file_path" 2>&1 | tail -20) || true
    fi
    ;;

  *.vue)
    # Vue 文件：eslint --fix
    if [ -f "$repo_root/package.json" ]; then
      (cd "$repo_root" && npx --no-install eslint --fix "$file_path" 2>&1 | tail -20) || true
    fi
    ;;
esac

exit 0
