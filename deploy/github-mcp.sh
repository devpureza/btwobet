#!/usr/bin/env bash
# Inicia o GitHub MCP Server usando o token do `gh auth login`.
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "Instale o GitHub CLI: brew install gh" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Faça login primeiro: gh auth login" >&2
  exit 1
fi

export GITHUB_PERSONAL_ACCESS_TOKEN
GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"

exec docker run -i --rm \
  -e GITHUB_PERSONAL_ACCESS_TOKEN \
  ghcr.io/github/github-mcp-server
