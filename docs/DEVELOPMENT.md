# Development rules

Canonical rules for all work in this repo. Back to [[index]].

1. **Incremental & stable.** Never rewrite working code wholesale. Make small, self-contained changes; preserve existing behavior; commit in small logical steps. New files are fine; large destructive refactors are not.
2. **Pre-commit review gate.** Before every `git commit`, spawn a `reviewer` subagent on the staged diff; for anything touching secrets, `env` handling, or the roots security check, also spawn `security-reviewer`. Fix findings; commit only when clean.
3. **Advisor gate for big changes.** Any architecture / API / approach change is preceded by an advisor pass: a `task` subagent doing an architecture critique plus `reviewer` (and `security-reviewer` when security-relevant). Optimize for security, scalability, cleanliness **without over-engineering** — target the simplest design a senior dev would ship for a small, quick setup.
4. **Concise Obsidian docs.** Keep the `docs/` vault (wikilinks + Mermaid) current with behavior changes; short notes only, no bloat.
5. **Green Docker suite.** Changes keep `docker compose run --rm omph-test` passing (the isolated-HOME logic suite in `test/run.sh`).

## Shell compatibility

`bin/omph` must run on macOS system bash 3.2 and GNU/Linux: no `mapfile`, associative arrays, `${var,,}`, or GNU-only flags without a BSD fallback.
