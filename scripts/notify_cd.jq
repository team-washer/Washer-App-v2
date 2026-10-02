# release.yml 배포 결과를 Discord embed(GitHub 웹훅 봇과 같은 카드 형식) payload 로 만든다.
# 입력은 전부 --arg 문자열. dry run 이 실패·경고 없이 끝나면 아무것도 출력하지 않는다(알림 생략).
# ios / android: Fastfile CD_RESULT JSON (fastlane 실행 전에 실패하면 빈 문자열)

def parsed(raw): if raw == "" then null else (raw | fromjson) end;
def trim(n): tostring | if length > n then .[0:n - 1] + "…" else . end;

def platform_value(job; raw; skip_reason):
  parsed(raw) as $r
  | if $r == null then
      if job == "failure" then "❌ 실패\n배포 준비 단계 (fastlane 실행 전)"
      elif job == "cancelled" then "⛔ 취소됨"
      else "⏭️ 건너뜀\n\(skip_reason)" end
    elif $r.status == "success" then "✅ \($r.summary)"
    elif $r.status == "dry_run" then "🧪 \($r.summary)"
    elif $r.status == "skipped" then "⏸️ 건너뜀\n\($r.summary)"
    else "❌ 실패 · `\($r.failed_step)`\n\($r.cause)" end
  | trim(1000);

def warnings(name; raw): [(parsed(raw).warnings? // [])[] | "**\(name)** \(.title)\n\(.cause)"];
def failed(job; raw): job == "failure" or job == "cancelled" or (parsed(raw).status? == "failure");

(failed($ios_job; $ios) or failed($android_job; $android)) as $failed
| (warnings("iOS"; $ios) + warnings("Android"; $android)) as $warnings
| if $dry_run == "true" and ($failed | not) and ($warnings | length) == 0 then empty
  else
    {
      embeds: [{
        author: { name: $actor, url: "https://github.com/\($actor)", icon_url: "https://github.com/\($actor).png" },
        title: ((if $failed then "❌ 배포 실패" else "🚀 배포 완료" end)
          + " · v\($version)" + (if $dry_run == "true" then " (dry run)" else "" end)),
        url: $run_url,
        description: "[`\($sha[0:7])`](\($repo_url)/commit/\($sha)) \($commit | trim(200))",
        # 실패 빨강 · 경고 노랑 · 성공 초록 (GitHub 색상)
        color: (if $failed then 13574702 elif ($warnings | length) > 0 then 13801762 else 3055683 end),
        fields: (
          [
            { name: "iOS", value: platform_value($ios_job; $ios; "실행되지 않음"), inline: true },
            { name: "Android",
              value: platform_value($android_job; $android;
                (if $android_configured == "false" then "Play Store 키 미설정" else "실행되지 않음" end)),
              inline: true }
          ]
          + (if ($warnings | length) > 0
             then [{ name: "⚠️ 확인 필요", value: ($warnings | join("\n\n") | trim(1000)), inline: false }]
             else [] end)
        ),
        footer: { text: "Release · \($repo)" },
        timestamp: $now
      }],
      allowed_mentions: { parse: [] }
    }
  end
