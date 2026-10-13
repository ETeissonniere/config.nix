---
name: eliott-style
description: Apply Eliott Teissonniere's observed engineering preferences to implementation, tests, documentation, commits, pull requests, and code reviews when asked to work in Eliott style or when those preferences are explicitly relevant to his own work.
---

# Eliott style

Use these preferences to make engineering choices and communicate them. They are inferred from selected GitHub activity, including some agent-assisted PRs; do not imitate personal voice, emoji, or historical library choices. Follow the user's current instructions and the repository's rules and conventions first.

## Implement

- Start from the observed failure, user-visible need, or operational cost. Trace the affected path and its existing contract before editing. If the cause is uncertain, name the hypothesis and check it.
- For a bug fix, inspect callers and fix the verified cause where the affected paths converge. A smaller diff that only hides one symptom leaves the work unfinished.
- Keep runtime and operations in view: error propagation, concurrency, migrations, CI time, cache behavior, CPU and memory, deployment effects, and recovery. Investigate the ones the change actually touches; quantify meaningful performance claims when practical.
- When validation disproves an approach, simplify or revert it instead of retaining it because it is already implemented.

## YAGNI loop

After understanding the affected flow and required contract, use this decision ladder. Stop at the first option that fully meets the need:

1. Does this need to exist? Skip speculative behavior, scaffolding, and configuration for hypothetical future needs.
2. Does the repository already solve it? Reuse an existing helper or pattern.
3. Does the standard library solve it? Use it.
4. Does a native platform feature solve it? Prefer it to custom machinery.
5. Does an installed dependency solve it? Reuse it before adding a dependency; do not add one for a few straightforward lines.
6. Otherwise, write the smallest clear implementation that works. Use one line when it remains readable and correct.

Prefer deletion over addition and explicit code over abstractions without a current use. Do not add interfaces, factories, extension points, or compatibility paths without a demonstrated requirement. Keep the diff focused; do not trade correctness or clarity for fewer lines.

Apply the ladder while implementing and reviewing. Before final validation, inspect the complete diff for unnecessary code, duplication, speculative behavior, and stale comments. Simplify, run the relevant checks, and repeat only when changes or failures justify another pass. Stop when the requested contract is met, checks pass, and no concrete simplification remains within scope; do not expand into unrelated cleanup.

Preserve explicit requirements, trust-boundary validation, security, data-loss prevention, accessibility, and needed hardware calibration or recovery. Simplicity shortens the solution, not the investigation or evidence needed to prove it works. Briefly explain a deliberate limitation only when it affects use, and name the concrete condition that would justify a more complex solution.

## Test

- Test observable contracts and plausible regressions, including meaningful success, error, and boundary cases. Assert the precise failure when it matters. For flaky tests, locate nondeterminism in the test or product before changing expectations. Favor compact scenarios or tables over duplicated cases and source-text checks that freeze an implementation.
- Keep CI tests deterministic and runnable without accidental credential or environment dependencies. Check the actual runtime, built artifact, or end-to-end path when mocks cannot prove the behavior. Distinguish a smoke check from deeper validation, and state what was not verified on live systems or hardware.

## Document

- Keep commands, defaults, prerequisites, and operational caveats aligned with the code. When setup or release steps matter, give readers an ordered path they can run and an expected outcome. Place a caveat near the step it qualifies.
- Explain non-obvious contracts, side effects, and ownership assumptions in code or API comments. Remove stale or duplicate prose; avoid comments that merely paraphrase function names. Match detail to the reader's task rather than filling a fixed template.

## Commits and pull requests

- Keep each commit coherent and give it a concrete, action-oriented subject. Follow the repository's commit convention if it has one; do not impose a single prefix style across projects.
- Write a PR so a reviewer can see the problem, the chosen fix, important tradeoffs, validation, and remaining limits. Use short prose or bullets as the change warrants; do not require a fixed template.
- Keep the PR bounded and disclose dependencies such as a stacked base when they affect review or release.
- Distinguish local checks, CI results, and live verification. State untested environments or rollout dependencies when they affect confidence. Ask reviewers focused questions only where a real decision remains.

## Review

- Identify the changed contract and its actual risks. Depending on the change, check boundaries, ownership and authorization, failure propagation, concurrency and state transitions, migrations, and operational consequences.
- Where behavior changed, check whether tests exercise its actual contract; do not demand new tests for prose-only edits. Challenge unused code, duplicate work, unnecessary abstraction, and custom machinery that existing project idioms can replace.
- Anchor feedback to the affected line or behavior. Explain the concrete risk and, when useful, offer a feasible fix. Phrase uncertainty as a question or hypothesis; be firm about demonstrated faults.
- Separate blockers from minor cleanup. Do not turn a worthwhile but unrelated refactor into a prerequisite. When responding to review, name the exact change and evidence that addresses the comment.
