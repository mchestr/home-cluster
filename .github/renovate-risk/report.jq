# Renders the assessment JSON as a PR comment / job summary.
# Blocking items stay visible; background detail is folded into <details>.
# Env: FIX_URL, RUN_URL, FLUX_LOCAL_RESULT. Arg: $marker.

def icon: {"low": "🟢", "medium": "🟡", "high": "🔴"}[.];
def verdict: {
  "low": "Low risk: safe to merge",
  "medium": "Medium risk: safe to merge, worth a glance",
  "high": "High risk: changes required before merge"
}[.];
def bullets(title; items):
  if (items | length) > 0 then "**\(title)**\n" + (items | map("- \(.)") | join("\n")) + "\n" else empty end;
# Label a source link by its last path segment (usually the release tag)
def source_links: map("[\(rtrimstr("/") | split("/") | last)](\(.))") | join(" · ");
def test_result: {"success": "✅ passed", "failure": "❌ failed"}[env.FLUX_LOCAL_RESULT] // env.FLUX_LOCAL_RESULT;

[
  $marker,
  "### \(.risk | icon) \(.risk | verdict)",
  "**\(.headline)**\n",

  (if (.updates | length) > 0 then
    "| | Package | Change |\n|:-:|---|---|\n"
    + (.updates | map("| \(.risk | icon) | `\(.package)` | `\(.from)` → `\(.to)` |") | join("\n"))
    + "\n"
  else empty end),

  bullets("💥 Breaking changes"; .breaking_changes),
  bullets("🛠️ Required actions"; .required_actions),
  (if env.FIX_URL != "" then "**🔧 Proposed fix:** #\(env.FIX_URL | split("/") | last)\n\(.fix_description)\n\nMerge it into this branch to apply.\n" else empty end),
  (if .risk == "high" then "> [!CAUTION]\n> This check fails until the problems above are fixed, so Renovate won't automerge.\n" else empty end),

  "<details><summary>Details</summary>\n",
  .summary + "\n",
  (.updates[] | "**`\(.package)`** `\(.from)` → `\(.to)` \(.risk | icon)\n\(.notes)\n\(if (.sources | length) > 0 then "\nSources: \(.sources | source_links)\n" else "" end)"),
  bullets("⚠️ Deprecations"; .deprecations),
  bullets("✨ New features worth adopting"; .new_features),
  "</details>\n",

  "<sub>flux-local test \(test_result) · [assessment run](\(env.RUN_URL))</sub>"
]
| join("\n")
# Link upstream repos via redirect.github.com so their issues and PRs don't get backlinks
| gsub("https://github\\.com/(?!\(env.GITHUB_REPOSITORY)/)"; "https://redirect.github.com/")
