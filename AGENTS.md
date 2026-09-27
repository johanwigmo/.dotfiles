# AGENTS.md

macOS dotfiles for GNU Stow (see README.md). **This repo is public — nothing sensitive lands here.**

## Rules

- Never commit secrets, tokens, credentials, or security posture details (what's unencrypted, where credentials live, hardening gaps)
- Secret values live only in `~/.config/dotfiles.env` (untracked, gitignored); `config/dotfiles.env.example` is the only tracked env file
- Machine/admin posture notes live in the private vault (`work/admin/`), never here
- Scripts treat missing secrets as a readable config error — never log or echo values
- Commit style: `file-or-topic: description` (matches existing history)
