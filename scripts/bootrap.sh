#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
if [[ "$PWD" != "$DOTFILES_DIR" ]]; then 
	echo "Error: Please run this script from $DOTFILES_DIR"
	exit !
fi

echo "===== Starting bootstrap ====="

############################
# Xcode Command Line Tools #
############################

if ! xcode-select -p &>/dev/null; then 
	echo "Installing Xcode Command Line Tools..."
	xcode-select --install || true
else 
	echo "Xcode Command Line Tools already installed"
fi

####################
# Install Homebrew #
####################

if ! command -v brew &>/dev/null; then
	echo "Installing Homebrew..."	
    	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
	eval "$(/opt/homebrew/bin/brew shellenv)"
else 
	echo "Homebrew already installed"
fi

##########################################
# Brew bundle (install apps + CLI tools) #
##########################################

echo "Tapping required repositories..."
brew tap FelixKratz/formulae
brew tap nikitabobko/tap

echo "Running Brew bundle..."
brew bundle --file="$HOME/.dotfiles/Brewfile"

###############################
# Create ~/.config if missing #
###############################

mkdir -p "$HOME/.config"

#################
# Stow dotfiles #
#################

cd "$HOME/.dotfiles"

echo "Stowing dotfiles..."

stow zsh
stow starship
stow tmux
stow git
stow nvim
stow zed
stow ghostty
stow aerospace

echo "Dotfiles stowed"

#########################
# Environment variables #
#########################

ENV_FILE="$HOME/.config/dotfiles.env"

if [ ! -f "$ENV_FILE" ]; then 
	echo "Creating environment file at $ENV_FILE"
	cp "$HOME/.dotfiles/config/dotfiles.env" "$ENV_FILE"
	echo "dotfiles.env installed"
else 
	echo "dotfiles.env already exists - skipping"
fi

#######################
# Tmux Plugin Manager #
#######################

echo "Installing TPM (Tmux Plugin Manager)..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then 
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

~/.tmux/plugins/tpm/bin/install_plugins

##################
# macOS Defaults #
##################

echo "Configuring macOS defaults"

# Appearance - Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Accessibility - Reduce motion
defaults write com.apple.Accessibility ReduceMotionEnabled -int 1

# Dock - Auto-hide
defaults write com.apple.dock autohide -bool true

# Keyboard - Enable full keyboard navigation (Tab through all controls)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Apply Dock changes
killall Dock

echo "macOS defaults applied!"

############
# Finalize #
############

echo "Reloading shell..."
exec zsh -l

echo "Bootstrap complete!"

