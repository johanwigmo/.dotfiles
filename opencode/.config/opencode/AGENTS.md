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
