#!/usr/bin/env bash
set -euo pipefail

echo "Updating dotfiles"
cd "$HOME/.dotfiles"
git pull

echo "Re-stowing configurations"
stow -R zsh
stow -R starship
stow -R tmux
stow -R git
stow -R nvim
stow -R zed
stow -R ghostty
stow -R aerospace

echo "Linking Claude Code config..."
ln -sf "$HOME/.dotfiles/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$HOME/.dotfiles/claude/settings.json" "$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents" "$HOME/.claude/hooks"
ln -sf "$HOME/.dotfiles/claude/skills/add-to-inbox" "$HOME/.claude/skills/add-to-inbox"
ln -sf "$HOME/.dotfiles/claude/skills/git-commit" "$HOME/.claude/skills/git-commit"
ln -sf "$HOME/.dotfiles/claude/agents/explorer.md" "$HOME/.claude/agents/explorer.md"
ln -sf "$HOME/.dotfiles/claude/hooks/notify-done.sh" "$HOME/.claude/hooks/notify-done.sh"

echo "Setting executable permissions for Claude Code hooks..."
find "$HOME/.claude/hooks" -type f -name "*.sh" -exec chmod +x {} \;

echo "Updating Homebrew and packages from Brewfile..."
brew update 
brew bundle --file="$HOME/.dotfiles/Brewfile"
brew upgrade --cask
brew cleanup

echo "Updating TPM plugins..."
~/.tmux/plugins/tpm/bin/update_plugins all

echo "Update complete!"

echo ""
echo "Note: If dotfiles.env changed, update it with: "
echo "    cp ~/.dotfiles/config/dotfiles.env ~/.config/dotfiles.env"
