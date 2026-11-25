# Review gates

pstack is the process (`.claude/extensions/pstack.md`). These are the gates
it runs on top before a PR goes to Ezra. A gate never replaces a pstack
step.

This package is one class, `ServiceException`, and its users are
everything else: the apps (chargeplus_customer, chargeplus_partner,
chargeplus_customer_web), the domain packages under their `packages/` that
extend it, and api_request_helper_flutter, which builds one for every
failed request. All of them pull it by unpinned git URL with gitignored
lock files. The class is small, so the gates spend their effort on the
contract: what a field, a constructor or the `props` list change does to
every subclass, every `catch` and every equality check in the fleet. CI
answers what a machine answers the same way every time; these gates keep
the judgement.

## The gates

| Gate | Runs when | How |
| --- | --- | --- |
| CI | every PR | `gh pr checks <n>` green on the head: `build` (format, analyze, tests; no coverage floor here), `semantic_pull_request` (the title) and `spell-check` (every `.md`, `.claude/` included: a new word goes in `.github/cspell.json`). |
| Tests | any change under `lib/` or `test/` | see [Tests](#tests) |
| Cleanup | any change under `lib/` or `test/` | `/pstack:no-comments`; `/simplify` adds nothing on a one-class diff, so skip it unless the diff passes ~100 lines |
| Code review | any change under `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml` or `.github/` | the built-in `/code-review` (it also checks CLAUDE.md rules), plus the [repo traps](#repo-traps) |
| Adversarial review | any change under `lib/` | `/pstack:interrogate`, Codex as its non-Claude seat. Each adversary gets the [lenses](#edge-case-lenses) and the repo traps as its starting brief. See [Adversarial review](#adversarial-review). |
| API compatibility | any change under `lib/` or to `pubspec.yaml` | classify the diff as **Additive**, **Behavior** or **Breaking** and name the bump: see [API compatibility](#api-compatibility) |
| Consumer impact | every change under `lib/` or to `pubspec.yaml` dependencies | see [Consumer impact](#consumer-impact) |
| Security | the diff touches `.github/workflows/` or adds a dependency | the built-in `/security-review`: actions pinned to a full SHA, `permissions:` no wider than the job needs. A new dependency is also a hard stop (CLAUDE.md keeps this package on `equatable` alone). |
| Public-API docs | the diff adds or changes a field, a constructor parameter or what equality compares | the dartdoc says what each field holds, who sets it (api_request_helper_flutter, a domain exception), and whether it takes part in equality. CI's `public_member_api_docs` lint only proves a doc exists. |
| Public repo | every PR | read the diff, the commit messages and the PR body for anything that must not be public: see [Public repo](#public-repo) |
| Agent instructions | the diff touches `CLAUDE.md`, `AGENTS.md`, `.claude/` or `.codex/` | a fresh agent reads every rule the diff adds or changes against `CLAUDE.md`, `.claude/extensions/pstack.md`, this file and every file the rule names (the skill, agent, hook or script it edits or points to), and quotes each conflict: two rules that disagree, a rule a later line undoes, a step that names a tool or path that does not exist, or anything that weakens a hard stop. Fix each one before the PR goes to Ezra. |
| Independent verdict | every PR except prose-only | pstack Shipping step 1, with a scratch consumer standing in for the apps: see [Independent verdict](#independent-verdict) |

Prose-only changes (only the `proseOnly` paths in `.github/review-gates.json`,
today `README.md`) run CI and Public repo only, and their Review gates
section is `None: prose-only`. Any other `.md` runs the gates its path
triggers (`CLAUDE.md`, `AGENTS.md` and `.claude/` the agent instructions
gate, `.github/` code review).

**Order:** cleanup → code review → interrogate → API compatibility →
consumer impact → security → public-API docs → public repo → agent
instructions → independent verdict. CI and Tests run on every head you
push: fix them before the verdict. Run the gates in sequence so each sees
the fixes from the ones before it. A fix that moves HEAD re-runs the gates
it affects.

## Triage rule

Every finding is **applied** or **skipped with a concrete, checkable
reason**. Never "I disagree". Roughly a third of agent findings are wrong:
verify before applying, and prove the skip when you can (a throwaway test,
then delete it).

**Fix them, do not just report them.** Commit each gate's fixes
separately in Conventional Commits (`refactor: …` for cleanup, `test: …`
or `fix: …` for review findings) and push them in the same pass. A gate is
not finished while its accepted findings sit uncommitted. A gate that
finds nothing says so; no empty commit.

Escalate instead of deciding alone when a fix would change intended
behavior, reach outside this package, or need a product call. Report it as
a finding you deliberately did not take, with the reason.

## Tests

Run `very_good test -j 4 --coverage --test-randomize-ordering-seed random`
on every head you push and diff the failing **name set** against
`origin/develop`, never the count. Every field and every `props` entry has
a test: one that sets it, and one that shows two instances differing only
in it are unequal (or equal, if it is left out of `props` on purpose).

For a bug fix, RED then GREEN must be on **the test that ships**: copy the
fixed file to the scratchpad, put the merge base's version in place
(`git show $(git merge-base origin/develop HEAD):lib/src/service_exception.dart`),
confirm the test fails, restore, confirm it passes. Quote the failure
message. Never stash.

## Adversarial review

Codex takes interrogate's non-Claude seat as the `codex` subagent with
`Mode: ask` (`.claude/agents/codex.md`). Put every adversary's findings
through interrogate's Verify step: a finding a run proves is confirmed, one
a run disproves is dropped with the output, and one that cannot be run here
is recorded as **verification-blocked** and triaged, never counted as
clean.

**When pstack is not installed in the checkout** (the SessionStart hook
says so), ask Ezra to install it or trust the folder. Until it loads, do
not skip the gate: run the panel by hand, one fresh subagent per entry of
the `interrogate reviewers` line in `.claude/rules/pstack-models.md`, all
in one message, each with the diff, the lenses, the repo traps and the
instruction to break the change and prove each finding with a run. The
Codex seat's brief skips the worker.md pair; a `CODEX UNAVAILABLE` reply
drops the seat with a note. Write "interrogate (panel run by hand: pstack
not installed)" in the Review gates block. `/pstack:no-comments` has no
hand-run form: mark it ❌ blocked with the reason.

### Edge-case lenses

Keep only the rows the diff reaches, and add the ones no lens names.

- **Subclasses:** a domain exception that extends `ServiceException` with
  a `const` constructor passing some or none of the named parameters, one
  that adds its own fields and `props`, and one the apps `switch` or
  `catch` on by type.
- **Equality:** two instances differing only in one field; with and
  without a `stackTrace` (`StackTrace.current` is never equal to another
  one); an exception held in an `Equatable` bloc state, where equality
  decides whether `buildWhen`, `listenWhen` and `emit` fire.
- **Construction:** `const` with no arguments, every field `null`, every
  field set; built by api_request_helper_flutter's `getException` from a
  status code.
- **Display:** what `toString()` prints in a log or a crash report, and
  whether that now includes a server message.

## API compatibility

List every change to what a consumer can see, then classify the PR by the
most severe one:

- **Additive** (minor bump): a new optional named field that is not in
  `props`, with a `const` constructor kept.
- **Behavior** (minor at least; Ezra decides): no signature breaks, but a
  consumer gets a different result: a field added to or removed from
  `props` (equality changes for every instance that sets it, so a bloc
  state that held an equal exception now emits), a changed `stringify` or
  `toString`, a field's meaning.
- **Breaking** (major bump): a field removed, renamed or retyped, a
  changed nullability, a constructor parameter made required or
  positional, a constructor that is no longer `const`, a raised `sdk`
  floor, or a dependency range that drops a version a consumer resolves
  today (`equatable` spans 2 and 3).
- **Internal** (patch): none of the above (tests, docs).

CLAUDE.md treats the class as additive-only in practice: Behavior and
Breaking are hard stops for Ezra (`pstack.md`, hard stop 1), and a
Breaking change updates every app and api_request_helper_flutter in one
coordinated sweep, or ships as add-new, migrate-callers, delete-old
across releases (`/pstack:principle-migrate-callers-then-delete-legacy-apis`).

## Consumer impact

1. Find every use of the class and of each changed field on each
   consumer's `develop`, without touching their working trees. `git grep`
   covers the apps' `packages/`:

   ```bash
   for c in chargeplus_customer chargeplus_partner chargeplus_customer_web api_request_helper_flutter; do
     git -C ../$c fetch -q origin develop
     git -C ../$c grep -n -e 'ServiceException' -e '<field>' origin/develop -- '*.dart'
   done
   ```

   Count the subclasses (`extends ServiceException`) and the tests that
   compare exceptions with `equals` or inside a state's `props`: those
   are where a `props` change lands. Stay out of every key file while you
   search. A missing sibling checkout marks the gate ⚠️ partial, naming
   it.
2. Run `/pstack:blast-radius` on the one or two facts the change's safety
   rests on, and take each as far down its "how sure are you" ladder as is
   cheap.
3. **Behavior or Breaking:** prove it against the real consumers. In a
   throwaway detached worktree of api_request_helper_flutter and of each
   affected app at `origin/develop` (`git -C ../<c> worktree add --detach <scratch> origin/develop`),
   point the affected package at this checkout with an uncommitted
   `pubspec_overrides.yaml` (`dependency_overrides: exceptions_flutter:
   {path: <this worktree>}`), run `flutter pub get`, `flutter analyze` and
   the tests of the packages that define or compare the exceptions, then
   remove the worktree. Never commit in a consumer, and never run anything
   there that needs its API keys.
4. Verdict: **Additive** with the grep evidence, or the subclasses, call
   sites and tests per repo that break or behave differently, with the
   consumer PRs linked or the gate ❌ blocked naming what is missing.

## Public repo

This repository is public on GitHub. The diff, the commit messages and the
PR body carry no:

- key, token, password, dart-define value or `.env` content;
- hostname, URL or endpoint path of a ChargePlus service;
- customer data, or a real server error message copied from a log as a
  test fixture;
- private ticket text or internal incident details.

A hit is fixed before the push. One already pushed goes to Ezra at once:
the history needs a rewrite he must approve.

## Independent verdict

pstack Shipping step 1: a fresh agent that did not write the code runs the
change the way the consumers would, parent against head, and posts `PASS`,
`PASS+NOTES` or `FAIL` on the PR with the full head SHA.

There is no app here, so the agent writes a scratch consumer in the
scratchpad (never committed): a Dart test that depends on this checkout by
path and uses the class the way the fleet does. It defines a domain
exception that extends it with a `const` constructor, throws it and
catches it as `on ServiceException`, compares instances with and without
a stack trace, holds one in an `Equatable` state, and prints it. It runs
the same test against the merge base and the head and quotes the
difference. When a behavior only shows inside one app, it posts
`PASS+NOTES (partial: <reason>)`, never a plain `PASS`.

A diff with nothing for a consumer to call (only `.claude/`, `.codex/`,
`.github/`, `CLAUDE.md`, `AGENTS.md` or a script) has no scratch
consumer. The agent runs each changed hook, script, workflow step or
skill command the way its caller does, on a scratch directory, at the
merge base and at the head, with one input that should change behavior
and one that should not (a hook gets its event's JSON on stdin). A
`pull_request` workflow that cannot run from the branch is
`PASS+NOTES (partial: <reason>)`. The `control-cli` skill runs this gate.

### Re-verdicts

A verdict covers one head SHA:

- **Same patch** (a rebase, or a merge-forward whose changed lines match):
  `git diff $(git merge-base origin/develop <sha>) <sha> | git patch-id --stable`
  prints the same ID for both heads. Post a re-check comment with both SHAs
  and the ID.
- **Fix commit:** a fresh agent checks only `git diff <verified head> <new
  head>` the way the full verdict ran, and posts a delta verdict that links
  the full one.
- **Anything else:** rerun the verdict.

## Repo traps

Interrogate adversaries and `/code-review` check the diff against these. A
trap that can become a lint, test or CI check should become one
(`/pstack:correct`), then leave this list.

- **`stackTrace` is in `props`.** Two exceptions with the same code and
  message are unequal when their stack traces differ, and
  `StackTrace.current` never equals another one. Consumer tests compare
  instances built without one. Any change to `props` changes equality
  fleet-wide.
- **Subclasses call a `const` super constructor** with optional named
  parameters. A required or positional parameter, or a constructor that
  is no longer `const`, breaks every domain exception at once.
- **`code` strings are the dispatch key** (`wrong-password` and the like),
  set by the domain packages and by api_request_helper_flutter's status
  mapping. This class defines no codes; keep it that way.
- **A pure data carrier.** No methods, no behavior, no dependency beyond
  `equatable` (CLAUDE.md). Its range spans `equatable` 2 and 3 because
  the apps resolve both.
- **`pubspec.lock` stays untracked.** A `.gitignore` typo once let it in
  (#8).

## The Review gates block

The PR body's `## Review gates` section, between the
`<!-- review-gates -->` markers that `.github/PULL_REQUEST_TEMPLATE.md`
carries. The `review-gates` skill writes it, the **Review gates** CI
check (`.github/scripts/review_gates_check.py`, its fields in
`.github/review-gates.json`) fails the PR until it is filled in, and
`cut-release` reads it. Read the body first
(`gh pr view <n> --json body`), replace between the markers, never
clobber the sections above it, and write it with
`gh pr edit <n> --body-file <file>`.

```
<!-- review-gates -->
## Review gates

- **Gates run:**
  - **<gate>:** ✅ / ⚠️ partial / ❌ blocked / n/a · <commit, test name, link or reason>
- **Independent verdict:** PASS / PASS+NOTES / FAIL · <comment link> · covers <full 40-character head SHA>
- **API change:** Additive / Behavior / Breaking / Internal → patch / minor / major
- **Verification-blocked:** none, or each check that could not run here and why
<!-- /review-gates -->
```

One **Gates run** sub-line per gate, in the order above, and `n/a` with
the missing trigger for a gate the diff does not reach. Mark a gate ⚠️
partial or ❌ blocked with its reason whenever it could not do its job.
**Verification-blocked** names those gates and every finding recorded as
verification-blocked, or says `none`. A green result needs evidence. A
prose-only change writes `None: prose-only` as the whole section.

The check fails on a `<…>` left in, a gate still `pending` (as a gate's
first or last word: inside a description, put the word in backticks),
a verdict other than `PASS` or `PASS+NOTES`, or a verdict SHA that is
not the PR head. A push after the verdict needs a re-verdict.
If the PR title no longer covers what the branch does, retitle it.

## Report

Per gate: findings, what was applied, what was skipped and why. Then the
API classification, the consumer-impact verdict with subclass and
call-site counts, CI and test results, the independent verdict, and the PR
URL. **Never merge.** Stop at Ezra's review, even if asked to "finish it".

## Rejected gates

- **Fuzz:** nothing is parsed or decoded here; api_request_helper_flutter
  fuzzes the path that builds the exception from a response.
- **Design laws, visual check, accessibility, user critics:** no UI.
- **i18n:** `displayMessageKey` is a key the apps translate; this package
  holds no copy.
- **Perf, Firebase cost, saved state, formal verification, release
  build:** none apply to an immutable data class.
- **Security beyond workflows and dependencies:** the class holds what its
  callers put in it. What reaches a log is the caller's gate
  (api_request_helper_flutter's Security gate covers its messages).
