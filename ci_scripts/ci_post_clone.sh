#!/bin/sh
set -euo pipefail

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"

if [ -x "$REPO_ROOT/ios/ci_scripts/ci_post_clone.sh" ]; then
  exec "$REPO_ROOT/ios/ci_scripts/ci_post_clone.sh"
fi

FLUTTER_VERSION="$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$REPO_ROOT/.fvmrc" | head -n 1)"
FLUTTER_DIR="$HOME/flutter"

write_env_file() {
  file_path="$1"
  file_contents="$2"
  printf '%s' "$file_contents" > "$file_path"
}

if [ -z "$FLUTTER_VERSION" ]; then
  FLUTTER_VERSION="stable"
fi

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics
flutter precache --ios

cd "$REPO_ROOT"

if [ -n "${ENV_PRODUCTION:-}" ]; then
  write_env_file "$REPO_ROOT/.env.production" "$ENV_PRODUCTION"
elif [ ! -f "$REPO_ROOT/.env.production" ]; then
  echo "error: ENV_PRODUCTION is required for Xcode Cloud builds." >&2
  exit 1
fi

if [ -n "${ENV_DEVELOPMENT:-}" ]; then
  write_env_file "$REPO_ROOT/.env.development" "$ENV_DEVELOPMENT"
elif [ ! -f "$REPO_ROOT/.env.development" ]; then
  # The development file is bundled as an asset, so keep a placeholder for CI archives.
  : > "$REPO_ROOT/.env.development"
fi

flutter pub get

cd "$REPO_ROOT/ios"
pod install
