# Usage

Flow: [[architecture]]. Profile contents: [[profiles]].

## Install

```bash
ln -s "$PWD/bin/omph" ~/.local/bin/omph   # ~/.local/bin on PATH; needs jq
```

## Example

```bash
omp                                   # /mcp add playwright, client-a-wiki, tracker ... (global pool)
omph :init base       && echo playwright    >> ~/.config/omph/profiles/base/mcp
omph :init client-a   && echo client-a-wiki >> ~/.config/omph/profiles/client-a/mcp
omph :init sales      && echo tracker       >> ~/.config/omph/profiles/sales/mcp
cd ~/code/client-a-website && omph :use base client-a sales
omph                                  # any omp args work: omph -p "...", omph --resume
```

## Commands

| Command | Effect |
|---|---|
| `omph :init <name> [--desc TEXT]` | Create a profile (idempotent) |
| `omph :use <profile>...` | Write `.omph` at the git top-level (else cwd) and trust it |
| `omph :trust` | Trust the nearest marker after you reviewed it (needed after clone or edit) |
| `omph :which` | Show resolved profiles, source, trust, per-profile contents |
| `omph :ls` | List profiles and their MCP servers |

## Marker `.omph`

```
# comments allowed
profiles = base, client-a, sales
```

Commit it or gitignore it; either way every clone needs `omph :trust` once.
