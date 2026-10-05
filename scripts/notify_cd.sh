#!/usr/bin/env bash

# release.yml notify 잡에서 호출한다. iOS·Android 배포 결과를 모아 Discord 로 배포당 메시지 1개를 보낸다.
# 메시지 형식은 notify_cd.jq 참고. 커밋 메시지·에러 원인 같은 외부 텍스트는 env 로만 받고 jq 로 직렬화한다(#315).
# 필요한 env: DISCORD_WEBHOOK, DRY_RUN, IOS_JOB, IOS_RESULT, ANDROID_JOB, ANDROID_RESULT, ANDROID_CONFIGURED
#            (GITHUB_* 는 Actions 기본 env)

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

if [ -z "${DISCORD_WEBHOOK:-}" ]; then
  echo "::warning::DISCORD_WEBHOOK 미설정 — 배포 알림을 건너뜁니다."
  exit 0
fi

VERSION_LINE="$(grep '^version:' "$ROOT_DIR/pubspec.yaml" | head -n 1 | awk '{print $2}')"
REPO_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY"

PAYLOAD="$(jq -n -f "$ROOT_DIR/scripts/notify_cd.jq" \
  --arg ios_job "${IOS_JOB:-}" --arg ios "${IOS_RESULT:-}" \
  --arg android_job "${ANDROID_JOB:-}" --arg android "${ANDROID_RESULT:-}" \
  --arg android_configured "${ANDROID_CONFIGURED:-}" \
  --arg dry_run "${DRY_RUN:-false}" \
  --arg version "${VERSION_LINE%%+*}" \
  --arg commit "$(git -C "$ROOT_DIR" log -1 --pretty=%s)" \
  --arg sha "$GITHUB_SHA" \
  --arg actor "$GITHUB_ACTOR" \
  --arg repo "$GITHUB_REPOSITORY" \
  --arg repo_url "$REPO_URL" \
  --arg run_url "$REPO_URL/actions/runs/$GITHUB_RUN_ID" \
  --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)")"

if [ -z "$PAYLOAD" ]; then
  echo "dry run 성공 — 알림을 보내지 않습니다."
  exit 0
fi
echo "$PAYLOAD" | jq .

RESPONSE_FILE="$(mktemp)"
STATUS="$(printf '%s' "$PAYLOAD" | curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -H "Content-Type: application/json" -X POST --data-binary @- "$DISCORD_WEBHOOK")"
case "$STATUS" in
  2*) ;;
  *) echo "::warning::Discord 알림 전송 실패 (HTTP $STATUS) $(head -c 300 "$RESPONSE_FILE")" ;;
esac
