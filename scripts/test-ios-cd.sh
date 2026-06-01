#!/usr/bin/env bash
#
# 로컬에서 iOS CD 의 archive(서명) 단계를 TestFlight 업로드 없이 재현·검증한다.
# main 에 push 하지 않고도 Fastfile/Podfile 서명 수정이 통과하는지 바로 확인할 수 있다.
#
# 사용법:
#   scripts/test-ios-cd.sh <PROVISIONING_PROFILE_UUID>
#   IOS_PROVISIONING_PROFILE_UUID=<uuid> scripts/test-ios-cd.sh
#
# 인자를 생략하면 설치된 프로비저닝 프로파일 목록(UUID)을 출력하고 종료한다.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# 프로비저닝 프로파일 경로: Xcode 16+ 신 경로 + 구 경로 모두 탐색
PROFILE_DIRS=(
  "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
  "$HOME/Library/MobileDevice/Provisioning Profiles"
)

# 프로비저닝 프로파일 UUID 결정: 인자 > 환경변수
PROFILE_UUID="${1:-${IOS_PROVISIONING_PROFILE_UUID:-}}"

if [ -z "$PROFILE_UUID" ]; then
  echo "❌ 프로비저닝 프로파일 UUID가 필요합니다."
  echo ""
  echo "사용법: scripts/test-ios-cd.sh <PROVISIONING_PROFILE_UUID>"
  echo ""
  echo "설치된 프로파일 (이름 → UUID):"
  for dir in "${PROFILE_DIRS[@]}"; do
    [ -d "$dir" ] || continue
    for p in "$dir"/*.mobileprovision; do
      [ -e "$p" ] || continue
      name=$(security cms -D -i "$p" 2>/dev/null | plutil -extract Name raw - 2>/dev/null || echo "?")
      uuid=$(security cms -D -i "$p" 2>/dev/null | plutil -extract UUID raw - 2>/dev/null || echo "?")
      echo "  - $name → $uuid"
    done
  done
  echo ""
  echo "💡 app-store 업로드용은 보통 'Store Provisioning Profile: com.washer.v2' 입니다."
  exit 1
fi

# update_code_signing_settings 가 Runner.xcodeproj/project.pbxproj 를 수정하므로,
# 로컬 작업 트리를 더럽히지 않도록 테스트 종료 시 원본으로 복원한다.
PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
PBXPROJ_BACKUP="$(mktemp)"
cp "$PBXPROJ" "$PBXPROJ_BACKUP"
restore_pbxproj() {
  cp "$PBXPROJ_BACKUP" "$PBXPROJ"
  rm -f "$PBXPROJ_BACKUP"
  echo "↩︎  project.pbxproj 원본 복원 완료"
}
trap restore_pbxproj EXIT

# pubspec.yaml 에서 버전명 추출 (CI 의 Resolve iOS version metadata 단계와 동일 로직)
VERSION_LINE="$(grep '^version:' pubspec.yaml | head -n 1 | awk '{print $2}')"
VERSION_NAME="${VERSION_LINE%%+*}"

export IOS_VERSION_NAME="$VERSION_NAME"
export IOS_BUILD_NUMBER="${IOS_BUILD_NUMBER:-9999}"   # 로컬 테스트용 임시 빌드번호
export IOS_PROVISIONING_PROFILE_UUID="$PROFILE_UUID"
export SKIP_TESTFLIGHT_UPLOAD=true                    # 업로드 단계 건너뜀

# 번들러(Gemfile.lock + 호환 Ruby)가 갖춰져 있으면 bundle exec, 아니면 글로벌 fastlane 사용
if [ -f Gemfile.lock ] && bundle exec fastlane --version >/dev/null 2>&1; then
  FASTLANE=(bundle exec fastlane)
else
  FASTLANE=(fastlane)
fi

echo "▶ 로컬 iOS CD 테스트"
echo "  version       : $IOS_VERSION_NAME"
echo "  build number  : $IOS_BUILD_NUMBER"
echo "  profile uuid  : $IOS_PROVISIONING_PROFILE_UUID"
echo "  upload        : SKIP"
echo "  fastlane      : ${FASTLANE[*]}"
echo ""

"${FASTLANE[@]}" ios upload_testflight
