# AGENTS.md

<!-- Fill this in before working with an agent in this repo. Keep it short — only what every session needs. Target under 60 lines. Everything here must be runnable headlessly — an unattended agent (opencode run, no GUI, nobody to ask) works from this file alone. -->

{One line: what this project is.}

## Agent contract

- Commits: {style — e.g. imperative one-liner matching `git log`, prefix conventions if any}. Branch: {main / feature/* / per-task}.
- Definition of done: {verification bar — e.g. build + tests green headlessly; `CHANGELOG.md` (keepachangelog) created at first ship-prep and maintained at every ship}.
- {Client repos: state the never-push rule + any scope borders (owned areas vs someone else's) + vault notes the agent must keep current.}
- {If `.scratch/` is gitignored: throwaway probes live there, append-only, never committed.}

## Build & verify

- Build: `{command}`
- Test: `{command}` — {fast vs full split if any; what "green" means for touched files}
- Lint/format: `{command}`
- {Stack run/verify specifics — simulator flows, variant prefixes, UI-test attachment export, screenshot capture for evidence. No GUI steps, nothing that prompts.}
- Update this file whenever a command or path changes.

## Conventions

- {Language/framework patterns, code style, naming}
- {Anything an agent would otherwise get wrong}

## Notes

- {Gotchas, architecture pointers, doc links}
