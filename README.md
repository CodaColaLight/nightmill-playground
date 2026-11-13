# nightmill playground

A throwaway repository for testing the [nightmill](https://github.com/CodaColaLight/nightmill) plugin
end to end: the first-session hook, `/nightmill:init` building a board from nothing, a story through
the whole flow. Nothing here is kept. Reset it whenever a test is over.

## Run a test

From a nightmill checkout you want to test (the working tree is what runs, no install needed):

```
cd nightmill-playground
claude --plugin-dir ../nightmill
```

Then, in the session: `/nightmill:init` (or wait for the hook to offer it), answer the questions, and
check the result on GitHub: the board with its Board view and eight columns, the labels, the issue
forms, `.claude/nightmill.json`.

To test the real install path instead (marketplace, version pinning, `claude plugin update`), run the
install commands from the nightmill README here, without `--plugin-dir`.

## Reset

```
bash reset.sh                                   # bash
powershell -ExecutionPolicy Bypass -File reset.ps1
```

The reset deletes, for this repository only: the project board named after the repository (or the
one in `.claude/nightmill.json`), the workflow labels (`epic`, `story`, `tech-debt`, `needs-spec`,
`blocked`, `area:*`, `prio:*`), all issues and milestones, every remote branch except `main`, and the
files the setup wrote (`.claude/`, `.github/ISSUE_TEMPLATE/`, `CLAUDE.md`, `docs/`). It then commits
and pushes. It refuses to run in any repository not named `nightmill-playground`.
