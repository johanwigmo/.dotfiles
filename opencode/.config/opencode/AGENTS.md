# Global Context

## About me
Solo iOS developer that builds indie apps while doing contracting mobile development (both Android and iOS). Favour simplicity, privacy and local-first/self-hosted solutions. 

## Working preferences
- Concise responses, no unnecessary preamble
- Show complete files unless very long, then show changed sections only
- Prefer scripts for deterministic/repetitive tasks; use judgment only where judgment is needed
- When uncertain, say so - don't guess

## Environment
- Shell: zsh, macOS
- Dotfiles: ~/.dotfiles via GNU Stow
- General editor: NeoVim
- Specific editor: Xcode (and Android Studio)

## Notes system
- Vault root: ~/Documents/notes
- Todo root: ~/Documents/notes/todo
- The vault is readable from dev sessions via external_directory allow; writes to it use the normal edit permission

## Delegation convention
Tasks tagged in backlogs/next-files are processed by the `process-delegated` skill in vault sessions — propose → confirm → execute:
- `@agent-{name}` — session work dispatched to the named agent skill (vault: coach-*, capture helpers, ...)
- `@dev-{project}` — development work for `~/Developer/{repo}`; collected and staged for that repo's own session (repo conventions live in the repo AGENTS.md — do not work cross-repo from vault sessions)
- Sub-tasks created while executing are indented checkboxes under the parent; parent marked `[/]`, completed `[x] YYYY-MM-DD` on completion
- Unclear tasks get `@clarify` instead of guessing

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
