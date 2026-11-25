# omph — OMP Harness

Run `omp` with **composable profiles**. A project's `.omph` marker (`profiles = base, client-a, 3d`) selects which MCP servers, skills, instructions and secrets apply; logins, sessions and models stay global. Unmarked directories get the `base` profile. Background and roadmap: `docs/brief.md`.

## Install

```bash
ln -s "$PWD/bin/omph" ~/.local/bin/omph   # ~/.local/bin on PATH; needs jq
```

## Commands

```bash
omph :init <name> [--desc TEXT]   # create profile
omph :use <profile>...            # bind this repo: write + trust .omph
omph :trust                       # trust a cloned/edited marker after review
omph :which                       # show resolved profiles
omph :ls                          # list profiles
omph [omp args...]                # launch omp with the resolved profiles
```

## Docs & tests

- `docs/` is an Obsidian vault: start at `docs/index.md`. Dev rules: `docs/DEVELOPMENT.md`.
- Tests: `bash test/run.sh` (host) or `docker compose run --rm omph-test` (isolated Linux, stub `omp`).
