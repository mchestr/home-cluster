#!/usr/bin/env bash
# Summarizes what merged to main in the last HOURS hours, with each change's
# risk assessment verdict, plus Renovate PRs waiting on a human. Writes
# markdown to $GITHUB_STEP_SUMMARY (or stdout) and sends a short Pushover
# notification when PUSHOVER_TOKEN and PUSHOVER_USER_KEY are set.
#
# Env: GH_REPO, HOURS (default 24), RUN_URL, RENOVATE_BOT (default mchesterbot[bot])
set -euo pipefail

HOURS="${HOURS:-24}"
RENOVATE_BOT="${RENOVATE_BOT:-mchesterbot[bot]}"
MARKER="<!-- renovate-risk -->"
since=$(date -u -d "-${HOURS} hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-"${HOURS}"H +%Y-%m-%dT%H:%M:%SZ)
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT

icon() { case "$1" in low) echo "🟢" ;; medium) echo "🟡" ;; high) echo "🔴" ;; *) echo "⚪" ;; esac; }

# "fix(container): update ghcr.io/home-operations/bazarr ( 1.6.1 → 1.6.2 )" -> "bazarr 1.6.1 → 1.6.2"
short_title() {
  sed -E 's/^[a-z]+(\([^)]*\))?!?: //I; s/^update //I; s#^([^ ]*/)+##; s/ \( (.*) \)$/ \1/' <<< "$1"
}

# Verdict "risk|headline" for a Renovate commit, from the assessment artifact
# uploaded by the Flux Local run on that exact commit.
commit_verdict() {
  local sha=$1 run dir="${work}/${1}"
  run=$(gh run list --workflow flux-local.yaml --event push --commit "${sha}" \
    --status completed --limit 1 --json databaseId --jq '.[0].databaseId // empty')
  if [[ -n "${run}" ]] && gh run download "${run}" --name renovate-risk --dir "${dir}" > /dev/null 2>&1; then
    jq -r '"\(.risk)|\(.headline // .summary)"' "${dir}/assessment.json"
  else
    echo "none|not assessed"
  fi
}

# Verdict "risk|headline" parsed from a PR's risk assessment comment
pr_verdict() {
  local body
  body=$(gh api "repos/${GH_REPO}/issues/$1/comments" --paginate \
    --jq "map(select(.body | startswith(\"${MARKER}\"))) | .[-1].body // empty")
  if [[ -z "${body}" ]]; then echo "none|not assessed"; return; fi
  local risk headline
  risk=$(grep -oiE '(low|medium|high) risk' <<< "${body}" | head -1 | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
  headline=$(grep -m1 -E '^\*\*[^*]' <<< "${body}" | sed -E 's/^\*\*(.*)\*\*$/\1/')
  echo "${risk:-none}|${headline}"
}

merged_md=() waiting_md=() waiting_txt=()
attention_txt=() low_names=() renovate_count=0
worst=none

bump() { # track the worst verdict seen
  case "$1:${worst}" in
    high:*) worst=high ;; medium:none|medium:low) worst=medium ;; low:none) worst=low ;;
  esac
}

# --- merged to main ---
while IFS=$'\t' read -r sha author title; do
  if [[ "${author}" == "${RENOVATE_BOT}" ]]; then
    IFS='|' read -r risk headline < <(commit_verdict "${sha}")
    name=$(short_title "${title}")
    link="https://github.com/${GH_REPO}/commit/${sha}"
    renovate_count=$((renovate_count + 1))
    bump "${risk}"
    # The notification lists what needs a look; low risk collapses to "name newversion"
    if [[ "${risk}" == low ]]; then
      low_names+=("$(sed -E 's/ [^ ]+ → / /' <<< "${name}")")
    else
      attention_txt+=("$(icon "${risk}") ${name} — ${headline}")
    fi
  else
    pr=$(gh api "repos/${GH_REPO}/commits/${sha}/pulls" --jq '.[0].number // empty')
    if [[ -n "${pr}" ]]; then
      IFS='|' read -r risk headline < <(pr_verdict "${pr}")
      link="https://github.com/${GH_REPO}/pull/${pr}"
    else
      risk=none headline="pushed directly"
      link="https://github.com/${GH_REPO}/commit/${sha}"
    fi
    name="${title}"
  fi
  merged_md+=("| $(icon "${risk}") | [${name}](${link}) | ${headline} |")
done < <(gh api "repos/${GH_REPO}/commits?sha=main&since=${since}&per_page=100" --paginate \
  --jq '.[] | [.sha, (.author.login // ""), (.commit.message | split("\n")[0])] | @tsv')

# --- Renovate PRs waiting on a human ---
while IFS=$'\t' read -r number title url; do
  IFS='|' read -r risk headline < <(pr_verdict "${number}")
  bump "${risk}"
  name=$(short_title "${title}")
  waiting_md+=("| $(icon "${risk}") | [#${number} ${name}](${url}) | ${headline} |")
  waiting_txt+=("$(icon "${risk}") #${number} ${name}")
done < <(gh pr list --author "app/${RENOVATE_BOT%\[bot\]}" --state open --json number,title,url \
  --jq '.[] | [.number, .title, .url] | @tsv')

# --- report ---
{
  echo "## Cluster digest: last ${HOURS}h"
  echo
  if (( ${#merged_md[@]} )); then
    echo "### Merged to main (${#merged_md[@]})"
    echo
    echo "| | Change | Assessment |"
    echo "|:-:|---|---|"
    printf '%s\n' "${merged_md[@]}"
    echo
  else
    echo "Nothing merged."
    echo
  fi
  if (( ${#waiting_md[@]} )); then
    echo "### Renovate PRs waiting on you (${#waiting_md[@]})"
    echo
    echo "| | PR | Assessment |"
    echo "|:-:|---|---|"
    printf '%s\n' "${waiting_md[@]}"
  fi
} > "${work}/digest.md"
cat "${work}/digest.md" >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"

# The notification covers Renovate only; your own merges are in the full digest
if (( renovate_count + ${#waiting_txt[@]} == 0 )); then
  echo "No Renovate activity to report"
  exit 0
fi

# --- notification (Pushover messages are capped at 1024 characters) ---
title="Cluster: ${renovate_count} updates merged"
(( ${#waiting_txt[@]} )) && title+=", ${#waiting_txt[@]} waiting"
lines=()
if (( ${#waiting_txt[@]} )); then
  lines+=("<b>Waiting on you</b>" "${waiting_txt[@]}")
fi
if (( ${#attention_txt[@]} )); then
  lines+=("<b>Merged, worth a look</b>" "${attention_txt[@]}")
fi
if (( ${#low_names[@]} )); then
  low_line=$(printf '%s, ' "${low_names[@]}")
  lines+=("<b>🟢 ${#low_names[@]} low risk</b>" "${low_line%, }")
fi
# Drop whole lines from the end until it fits, leaving room for the pointer
message=""
for line in "${lines[@]}"; do
  if (( ${#message} + ${#line} > 980 )); then
    message+="… more in the full digest"
    break
  fi
  message+="${line}"$'\n'
done
if (( ${#message} > 1024 )); then
  message="${message:0:1000}…"
fi
# Quiet when everything is low risk; normal priority when something needs a look
priority=-1
[[ "${worst}" == medium || "${worst}" == high || ${#waiting_txt[@]} -gt 0 ]] && priority=0

if [[ -z "${PUSHOVER_TOKEN:-}" || -z "${PUSHOVER_USER_KEY:-}" ]]; then
  printf 'Pushover not configured; would send:\n[%s] (priority %s)\n%s\n' "${title}" "${priority}" "${message}"
  exit 0
fi
curl --silent --show-error --fail \
  --form-string "token=${PUSHOVER_TOKEN}" \
  --form-string "user=${PUSHOVER_USER_KEY}" \
  --form-string "title=${title}" \
  --form-string "message=${message}" \
  --form-string "html=1" \
  --form-string "priority=${priority}" \
  --form-string "url=${RUN_URL:-https://github.com/${GH_REPO}/commits/main}" \
  --form-string "url_title=Full digest" \
  https://api.pushover.net/1/messages.json > /dev/null
echo "Sent: ${title}"
