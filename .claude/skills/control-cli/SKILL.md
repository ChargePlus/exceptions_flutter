---
name: control-cli
description: "pstack's control-cli step (Shipping step 1, Feature step 5) in exceptions_flutter (cursor-team-kit's control-cli does not exist in Claude Code): use the class the way the fleet does and give PASS, PASS+NOTES or FAIL. Runs the independent-verdict procedure in .claude/extensions/review/gates.md. Use when a pstack playbook says control-cli or control-ui, or for the Independent verdict line of the PR's Review gates section."
---

# control-cli: the independent verdict

pstack's Shipping step 1 and Feature step 5 call `control-cli` (or
`control-ui`; this package has no UI, so both land here). In this repo it
is the **Independent verdict** gate. The procedure is in
`.claude/extensions/review/gates.md` → *Independent verdict* and
*Re-verdicts*: read it and follow it. This skill adds nothing to it.

1. **Who.** A fresh agent that did not write the code. The author never
   gives its own verdict.
2. **The run.** For a `lib/` or `pubspec.yaml` change, the scratch
   consumer: a Dart test in the scratchpad that depends on this checkout
   by path, defines a domain exception extending `ServiceException` with a
   `const` constructor, throws and catches it as `on ServiceException`,
   compares instances with and without a stack trace, holds one in an
   `Equatable` state and prints it, at the merge base and at the head.
   For a change with no consumer to stand in for (`.claude/`, `.github/`,
   `script.sh`), run each changed command the way its caller does, parent
   against head, as gates.md says. First ask whether the run can tell
   fixed from broken; if it cannot, the verdict is
   `PASS+NOTES (partial: <why>)` at best.
3. **What it cannot run.** A behavior that only shows inside one app:
   list it on the **Verification-blocked** line, never as clean.
4. **The verdict.** Post `PASS`, `PASS+NOTES` or `FAIL` as a PR comment
   with the full 40-character head SHA it covers and the quoted
   difference, then put the same on the PR body's Independent verdict
   line: `PASS · <comment link> · covers <sha>`. A newer head needs a
   re-verdict (gates.md, *Re-verdicts*), or the Review gates check stays
   red.

Nothing from the scratch consumer is committed. This repo is public: no
real server message or customer data in the comment.
