#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [debug|release]\n' "$0" >&2
  exit 2
fi

case "${1:-debug}" in
  debug)
    task_product=default
    task_mode=debug
    task_args=(--mode module -p module=entry@default)
    task_target=assembleHap
    ;;
  release)
    task_product=release
    task_mode=release
    task_args=(--mode project)
    task_target=assembleApp
    ;;
  *)
    printf 'Usage: %s [debug|release]\n' "$0" >&2
    exit 2
    ;;
esac

task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_deveco="${DEVECO_STUDIO_HOME:-}"
if [[ -z "$task_deveco" ]]; then
  for task_candidate in "$HOME/Applications/DevEco-Studio.app" /Applications/DevEco-Studio.app; do
    if [[ -f "$task_candidate/Contents/tools/hvigor/bin/hvigorw" ]]; then
      task_deveco="$task_candidate"
      break
    fi
  done
fi

task_hvigor="$task_deveco/Contents/tools/hvigor/bin/hvigorw"
if [[ -z "$task_deveco" || ! -x "$task_hvigor" ]]; then
  printf 'Set DEVECO_STUDIO_HOME to your DevEco-Studio.app directory.\n' >&2
  exit 1
fi

export NODE_HOME="${NODE_HOME:-$task_deveco/Contents/tools/node}"
export JAVA_HOME="${JAVA_HOME:-$task_deveco/Contents/jbr}"
export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$task_deveco/Contents/sdk}"

cd "$task_root"
printf 'Building product=%s, buildMode=%s (%s)\n' "$task_product" "$task_mode" "$task_target"
exec "$task_hvigor" "${task_args[@]}" -p "product=$task_product" \
  -p "buildMode=$task_mode" "$task_target" --no-daemon
