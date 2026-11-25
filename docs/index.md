# omph — OMP Harness

`omph` runs `omp` on your global OMP setup (one set of logins, sessions, models, extensions) and layers **composable profiles** on top. A project's `.omph` marker names its profiles, e.g. `profiles = base, client-a, 3d`; each profile contributes MCP servers, skills, instructions and secrets. A directory with no marker gets the `base` profile. Beads memory stays per project (`bd`'s own `.beads`).

- [[brief]] — problem, decisions, roadmap
- [[architecture]] — how a run is resolved and launched
- [[usage]] — install, commands, marker
- [[profiles]] — what a profile contains and how profiles combine
- [[DEVELOPMENT]] — rules for working on this repo
