#!/usr/bin/env bash
# reset.sh - put the playground back to an empty repository with no board, no labels, no issues.
# Refuses to run anywhere but a repository named nightmill-playground. Needs git and gh (no jq).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
case "$repo" in */nightmill-playground) ;; *) echo "refusing: $repo is not the playground"; exit 1;; esac
owner=${repo%/*}
echo "== resetting $repo"

# Board: number from the config if present, else every board titled like the repository.
nums=""
if [ -f .claude/nightmill.json ]; then
  nums=$(grep -o '"projectNumber"[[:space:]]*:[[:space:]]*[0-9]*' .claude/nightmill.json | grep -o '[0-9]*$' || true)
fi
if [ -z "$nums" ]; then
  nums=$(gh project list --owner "$owner" --format json --jq '.projects[] | select(.title=="nightmill-playground") | .number')
fi
for n in $nums; do
  title=$(gh project view "$n" --owner "$owner" --format json --jq .title 2>/dev/null || true)
  if [ "$title" = "nightmill-playground" ]; then
    gh project delete "$n" --owner "$owner" && echo "deleted board $n"
  else
    echo "left board $n alone (title '$title' is not nightmill-playground)"
  fi
done

# Labels the workflow creates.
gh label list --json name --jq '.[].name' | while IFS= read -r l; do
  case "$l" in
    epic|story|tech-debt|needs-spec|blocked|area:*|prio:*) gh label delete "$l" --yes >/dev/null && echo "deleted label $l";;
  esac
done

# Issues and milestones.
gh issue list --state all --limit 500 --json number --jq '.[].number' | while read -r i; do
  gh issue delete "$i" --yes >/dev/null && echo "deleted issue #$i"
done
gh api "repos/$repo/milestones?state=all" --jq '.[].number' | while read -r m; do
  gh api -X DELETE "repos/$repo/milestones/$m" >/dev/null && echo "deleted milestone $m"
done

# Branches other than main.
git fetch -q --prune
git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin | { grep -vx -e main -e HEAD || true; } | while read -r b; do
  git push -q origin --delete "$b" && echo "deleted branch $b"
done

# Files the setup wrote.
git switch -q main && git pull -q
git rm -rq --ignore-unmatch .claude .github/ISSUE_TEMPLATE CLAUDE.md docs
rm -rf .claude .github/ISSUE_TEMPLATE CLAUDE.md docs
if ! git diff --cached --quiet; then
  git commit -qm "reset playground" && git push -q && echo "removed setup files"
else
  echo "no setup files to remove"
fi
echo "RESET DONE"
