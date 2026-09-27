# Global Codex Preferences

## Finish the requested work
- Treat action requests as authorization to complete the task through validation and delivery. Reuse permission already given; stay within its scope.
- Resolve routine choices from context and repo conventions. Ask only when missing information materially changes the result, continuing independent work meanwhile. Prepare a concrete result before requesting additional authorization.
- Explicit user instructions take precedence over skill guidelines. Explain and identify any instruction that actually blocks progress.

## Keep work and context small
- Follow KISS; prefer explicit over implicit. Favor deletion, existing helpers, standard libraries, and native features over new abstractions or dependencies. Preserve required behavior and compatibility contracts; do not add speculative compatibility. Ask when compatibility requirements are unclear and affect the design.
- Read the relevant instructions and trace the affected behavior. Search narrowly, load references only when needed, and reuse established facts instead of rereading whole files or dumping logs.
- Use descriptive names and small, single-purpose functions. Document why, not what; comment only when the reason is not evident. Do not create README or documentation files unless requested.
- Use UV to manage Python environments and dependencies and to run Python scripts and tools. When authoring Python packages, use `uv_build` as the build backend unless specified otherwise. Running a tool does not require changing its build backend.
- Use cargo for Rust. Use relevant existing formatters, linters, and language servers.
- Inspect existing devcontainer, Compose, and Dockerfile setups first. For missing tools, prefer a compatible existing container environment, Apple's `container` when available, or Docker over asking the user to install tools on the host.

## Validate and deliver
- Before final validation, make a simplification pass over the complete diff, including delegated changes. Remove unnecessary abstractions, duplication, speculative behavior, and stale comments while preserving required behavior and preferences. Keep the pass within scope; do not turn it into an unrelated rewrite.
- Test user-visible behavior and contracts, not incidental structure or wording. Use descriptive scenario names and table-driven cases where useful. Add coverage when it can catch a real regression; avoid tests that mirror the implementation.
- Inspect repo automation before finishing committed or pushed work. Run relevant formatting, lint, type, build, and test checks plus required repo checks. Reproduce CI locally where practical; report any meaningful gap.
- Stop repeating or broadening passing checks unless new changes, failures, or unresolved risks justify it. Consider an independent adversarial review of correctness, style, and maintainability when complexity or risk warrants it.
- Check `git status` before committing. Keep commits atomic and explain why. Preserve unrelated work.
- Lead with the outcome in concise, plain language. Use concrete nouns and direct verbs; keep technical terms when they improve precision and explain unfamiliar ones. Avoid unnecessary jargon, invented labels, stock AI phrases ("delve", "leverage", "it is worth noting"), filler praise, and repetitive summaries. Match detail and formatting to the task.
- Report changes, meaningful validation, and blockers; distinguish local checks, CI, and live verification.
