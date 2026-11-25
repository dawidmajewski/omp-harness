# Brief

Why `omph` exists and where it is going. How it works: [[architecture]], [[profiles]], [[usage]].

## Problem

[OMP (oh-my-pi)](https://github.com/can1357/oh-my-pi) works well across many projects, but its context is all-or-nothing: every session sees the same MCP servers, skills, instructions and secrets. With many clients and products on one laptop:

- some projects should share context (same client, same tooling), others must not (different clients);
- the shareable units cut across projects: a browser MCP almost everywhere, a client's wiki MCP in that client's projects, a 3D skill set in 3D projects regardless of client;
- secrets and MCP tokens of one client must not leak into another client's sessions.

Longer term: send tasks from one place, route them to the right project, and run them unattended with retries, several agents at once and basic telemetry.

## Constraints

- Runs standalone on the laptop, configured locally. No third-party services.
- OMP stays the agent; everything else wraps it.
- The simplest approach wins; no directory layout is imposed on projects.

## Design

`omph` wraps `omp`. A project's `.omph` marker lists profiles (`profiles = base, client-a, 3d`); each profile contributes MCP servers, skills, instructions, settings and secrets, and they add up. Directories without a marker get `base`.

| Topic | Decision | Why |
|---|---|---|
| Scoping | Overlay per run on the global OMP base, not OMP's `OMP_PROFILE` | `OMP_PROFILE` takes one name (no composition) and isolates logins |
| Logins, sessions, models | Global | One login; sessions searchable in one place |
| MCP | One global pool (`~/.omp/agent/mcp.json`); each run disables servers the selected profiles don't name | OMP overlays cannot add MCP servers, but can disable them (`disabledExtensions: mcp:<name>`) |
| Memory (Beads) | Per project, `bd`'s own `.beads` discovery | Project issues stay with the project |
| Binding | Marker in the project + local trust list (sha256 + path), like direnv | Travels with the project; a cloned or edited marker can't claim profiles until reviewed |
| Unmarked dirs | `base` profile | The common tools everywhere; keep secrets out of `base` |

## Roadmap: task inbox and dispatcher

One folder queue plus one dispatcher script run on a timer; an empty queue costs nothing.

- **Task**: a markdown file with frontmatter (`project`, `attempts`), added by a one-line command or anything that writes a file.
- **State = folder** (`inbox/`, `running/`, `done/`, `failed/`): `mv` is atomic, so no locks and no database.
- **Routing**: explicit project first. Otherwise a cheap model picks from a registry of bound projects (the trust list already lists every approved marker) with profile descriptions; an invalid answer or low confidence goes to `failed/`. The router never guesses silently.
- **Running**: one git worktree per task; runs `omph --mode json -p`; OMP's subagents handle parallelism inside a task.
- **Limits**: 1 task per project, N in total, via `flock`.
- **Retry**: attempts +1, backoff 1 / 5 / 30 min; after 3 attempts the task goes to `failed/`.
- **Result**: commit on branch `agent/<id>`, summary in the task file, desktop notification. The agent never pushes or merges.
- **Timer**: `systemd --user` or `launchd`, one pass per minute; stateless, orphaned `running/` tasks return to the queue.
- **Telemetry**: a JSON log per task; tokens and cost via `jq`.
- **Safety minimum**: worktree, no push credentials in profile `env`, marker trust. Next step if needed: worker in a container with only the worktree mounted.

## Open questions

- Worktrees: trust is keyed by marker path, so each task worktree needs its marker trusted (dispatcher runs `omph :trust`, or trust keys on repo identity). Gitignored markers are missing in fresh worktrees.
- Does `omp --mode json` exit non-zero on error like `-p`? The retry logic depends on it.
