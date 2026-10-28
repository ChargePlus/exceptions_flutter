---
name: routine
description: "Run the four-pass pre-merge routine on an exceptions_flutter branch or PR — /simplify, /code-review, the CI gates locally, and a consumer-impact check across the apps and api_request_helper_flutter — triaging every finding and committing each pass separately. Stops at the human review gate; never merges. Use for: the routine, run the routine, quality passes, pre-merge checks, has this done the routine."
---

# Pre-merge routine (library edition)

A trimmed port of chargeplus_customer's five-pass routine. The app-only
passes (`driver-critic`, `deep-review`, `verify-sim`) don't apply to a
one-class library; the consumer-impact pass replaces them, because
`ServiceException` is the base exception contract for the whole fleet
(CLAUDE.md, blast-radius rules).

Run all four passes on every PR that touches `lib/`. Docs-, test- or
config-only PRs: pass 3 only — CI covers the rest.

## Order

**`/simplify` → `/code-review` → gates → consumer impact.**

The two passes that change code run first; the gates and the impact check
then judge the code that will actually merge. Never run passes in parallel.

## Preflight

```bash
git fetch origin develop --quiet
git diff origin/develop...HEAD --stat     # scope
git status --short                        # must be clean; never stash
flutter pub get                           # a fresh worktree needs it
```

## Triage rule

Every finding is **applied** or **skipped with a concrete, checkable
reason** — never "I disagree". Roughly a third of agent findings are wrong:
verify before applying, and prove the skip when you can (a throwaway test,
then delete it).

**Fix, don't just report.** Commit each pass separately (Conventional
Commits — CI checks the PR title too) and push it in the same pass. A pass
is not finished while its accepted findings sit uncommitted.

## Pass 3 — gates

The CI gates (`./script.sh` option 3), run locally before pushing:

```bash
dart format --line-length 80 --set-exit-if-changed lib test
flutter analyze lib test
very_good test -j 4 --coverage --test-randomize-ordering-seed random
```

Then confirm the PR's CI (`gh pr checks <n>`) is green, including the
markdown spell check: a new word in any `.md` goes in
`.github/cspell.json` `words`, not a misspelling. Every field and `props`
entry must be covered by a test.

## Pass 4 — consumer impact

1. List the contract change in `lib/src/service_exception.dart`: fields
   added/removed/renamed, nullability, constructor params, `props` (which
   changes equality everywhere), any new dependency or behavior.
2. Find the callers on each consumer's `develop` without touching their
   working trees (sibling checkouts). Search the class and every changed
   field name:

   ```bash
   for c in chargeplus_customer chargeplus_partner chargeplus_customer_web api_request_helper_flutter; do
     git -C ../$c fetch -q origin develop
     git -C ../$c grep -n -e 'ServiceException' -e '<field>' origin/develop -- '*.dart'
   done
   ```

   A missing sibling checkout → mark the pass ⚠️ partial and name it.
3. Verdict, one of:
   - **Additive** — a new optional field, nothing else. Say so with the
     grep evidence; note that a new `props` entry still changes equality
     for instances that set it.
   - **Breaking** — anything else in the CLAUDE.md list. Every consumer
     must change in one coordinated sweep: link the consumer PRs, or mark
     the pass ❌ blocked with what is missing.

## Update the PR after every pass

Keep the routine's state in the PR body, in one marked block that a re-run
replaces:

```
<!-- routine:status -->
### Quality routine

| Pass | Status | Findings | Commit |
| --- | --- | --- | --- |
| /simplify | ✅ done | 1 → skipped | — |
| /code-review | ✅ done | 0 | — |
| gates | ✅ green | format · analyze · test · CI | — |
| consumer impact | ✅ additive | 0 call sites break | — |

<what was skipped and why — one line each>
<!-- /routine:status -->
```

Read the body first (`gh pr view <n> --json body`), replace between the
markers if present, otherwise append; never clobber the template sections.
Write the body to a scratchpad file and `gh pr edit <n> --body-file <file>`.
Mark a pass ⚠️ partial or ❌ blocked with its reason — a table of green
ticks where one pass proved nothing is worse than no routine.

## Report

Per pass: findings, applied, skipped **and why**; the gate results; the
consumer-impact verdict with call-site counts; the PR URL. **Never merge —
stop at the human review gate**, even if asked to "finish it".
