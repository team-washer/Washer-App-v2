#!/usr/bin/env bash

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

ensure_env_file() {
  local target_file="$1"
  local example_file="$2"

  if [ -f "$ROOT_DIR/$target_file" ]; then
    return
  fi

  if [ ! -f "$ROOT_DIR/$example_file" ]; then
    echo "Missing example file: $example_file" >&2
    exit 1
  fi

  cp "$ROOT_DIR/$example_file" "$ROOT_DIR/$target_file"
  echo "Created $target_file from $example_file"
}

ensure_env_file ".env.development" ".env.development.example"
ensure_env_file ".env.production" ".env.production.example"
