#!/usr/bin/env bash
# GitHub MCP — token do `gh auth` ou, se não houver, do Keychain do macOS (mesmo do git push).
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker não encontrado. Abra o Docker Desktop." >&2
  exit 1
fi

github_token() {
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh auth token
    return 0
  fi

  if command -v git >/dev/null 2>&1; then
    local from_keychain
    from_keychain="$(
      printf "protocol=https\nhost=github.com\n\n" \
        | git credential-osxkeychain get 2>/dev/null \
        | awk -F= '/^password=/{print $2; exit}'
    )"
    if [ -n "$from_keychain" ]; then
      echo "$from_keychain"
      return 0
    fi
  fi

  return 1
}

TOKEN="$(github_token || true)"
if [ -z "$TOKEN" ]; then
  echo "Sem token GitHub. Rode: gh auth login" >&2
  exit 1
fi

export GITHUB_PERSONAL_ACCESS_TOKEN="$TOKEN"

exec docker run -i --rm \
  -e GITHUB_PERSONAL_ACCESS_TOKEN \
  ghcr.io/github/github-mcp-server
