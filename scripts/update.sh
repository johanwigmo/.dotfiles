#!/usr/bin/env bash
set -euo pipefail

echo "Updating dotfiles"
cd "$HOME/.dotfiles"
git pull

echo "Re-stowing configurations"
stow -R zsh
stow -R starship
stow -R herdr
stow -R tmux
stow -R git
stow -R nvim
stow -R zed
stow -R ghostty
stow -R borders

echo "Linking Claude skills (opencode compat)..."
mkdir -p "$HOME/.claude/skills"
for skill in add-to-inbox git-commit grill-me handoff; do
	ln -sfn "$HOME/.dotfiles/claude/skills/$skill" "$HOME/.claude/skills/$skill"
done

echo "Linking OpenCode config..."
mkdir -p "$HOME/.config/opencode"
ln -sf "$HOME/.dotfiles/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
ln -sf "$HOME/.dotfiles/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

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
