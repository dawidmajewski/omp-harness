# Profiles

How they are applied: [[architecture]].

A profile is a directory `~/.config/omph/profiles/<name>/`; every file is optional:

| File | Contents |
|---|---|
| `mcp` | MCP server names from the global pool `~/.omp/agent/mcp.json`, one per line |
| `skills/` | `<skill>/SKILL.md` directories |
| `instructions.md` | Text appended to the system prompt |
| `config.yml` | OMP settings overlay, e.g. `modelRoles` (not `disabledExtensions` / `skills.customDirectories`) |
| `env` | Secrets, exactly one `KEY=VALUE` (optional `export `) per line, mode `600` |
| `desc` | One-line description for `:ls` |

## Combining

- A project lists profiles left to right: `profiles = base, client-a, 3d`. MCP servers, skills and instructions add up; for `env` and `config.yml` values, later profiles win.
- Share anything by putting it in a profile several projects list (e.g. `base` with playwright).
- `base` is also what an unmarked directory gets. Without a `base` profile, unmarked directories run plain `omp` (every pool server).
- Logins, sessions, models and extensions are global (`~/.omp/agent`), never per profile.
- Beads memory is per project: `bd` finds the repo's own `.beads`; omph does not touch it.
- Nested `omph` runs unset the outer profiles' env keys (not restore): a key that overrides a global value is absent there, not leaked.
