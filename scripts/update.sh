#!/usr/bin/env bash
set -euo pipefail

echo "Updating dotfiles"
cd "$HOME/.dotfiles"
git pull

echo "Updating Homebrew..."
brew update && brew upgrade && brew cleanup

echo "Updating TPM plugins..."
~/.tmux/plugins/tpm/bin/update_plugins all

echo "Update complete!"
