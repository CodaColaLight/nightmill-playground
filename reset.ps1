# reset.ps1 - put the playground back to an empty repository with no board, no labels, no issues.
# Refuses to run anywhere but a repository named nightmill-playground. Needs git and gh.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$repo = gh repo view --json nameWithOwner --jq .nameWithOwner
if ($repo -notlike "*/nightmill-playground") { Write-Error "refusing: $repo is not the playground"; exit 1 }
$owner = $repo.Split("/")[0]
Write-Host "== resetting $repo"

# Board: number from the config if present, else every board titled like the repository.
$nums = @()
if (Test-Path .claude/nightmill.json) {
  $cfg = Get-Content .claude/nightmill.json -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($cfg.github.projectNumber) { $nums = @($cfg.github.projectNumber) }
}
if ($nums.Count -eq 0) {
  $nums = @(gh project list --owner $owner --format json --jq '.projects[] | select(.title==\"nightmill-playground\") | .number')
}
foreach ($n in $nums) {
  if (-not $n) { continue }
  $title = gh project view $n --owner $owner --format json --jq .title
  if ($title -eq "nightmill-playground") { gh project delete $n --owner $owner | Out-Null; Write-Host "deleted board $n" }
  else { Write-Host "left board $n alone (title '$title' is not nightmill-playground)" }
}

# Labels the workflow creates.
foreach ($l in @(gh label list --json name --jq '.[].name')) {
  if ($l -in @("epic", "story", "tech-debt", "needs-spec", "blocked") -or $l -like "area:*" -or $l -like "prio:*") {
    gh label delete $l --yes | Out-Null; Write-Host "deleted label $l"
  }
}

# Issues and milestones.
foreach ($i in @(gh issue list --state all --limit 500 --json number --jq '.[].number')) {
  if ($i) { gh issue delete $i --yes | Out-Null; Write-Host "deleted issue #$i" }
}
foreach ($m in @(gh api "repos/$repo/milestones?state=all" --jq '.[].number')) {
  if ($m) { gh api -X DELETE "repos/$repo/milestones/$m" | Out-Null; Write-Host "deleted milestone $m" }
}

# Branches other than main.
git fetch -q --prune
foreach ($b in @(git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin)) {
  if ($b -and $b -ne "main" -and $b -ne "HEAD") { git push -q origin --delete $b; Write-Host "deleted branch $b" }
}

# Files the setup wrote.
git switch -q main; git pull -q
git rm -rq --ignore-unmatch .claude .github/ISSUE_TEMPLATE CLAUDE.md docs
foreach ($p in @(".claude", ".github/ISSUE_TEMPLATE", "CLAUDE.md", "docs")) { if (Test-Path $p) { Remove-Item -Recurse -Force $p } }
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { git commit -qm "reset playground"; git push -q; Write-Host "removed setup files" }
else { Write-Host "no setup files to remove" }
Write-Host "RESET DONE"
