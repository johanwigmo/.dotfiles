#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
if [[ "$PWD" != "$DOTFILES_DIR" ]]; then
	echo "Error: Please run this script from $DOTFILES_DIR"
	exit 1
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

if command -v mas &>/dev/null && ! mas account &>/dev/null; then
	echo "Not signed in to the App Store - mas apps in the Brewfile will fail"
	echo "Sign in via the App Store app, then re-run this script"
fi

echo "Running Brew bundle..."
if ! brew bundle --file="$HOME/.dotfiles/Brewfile"; then
	echo "Warning: some Brewfile items failed to install"
	echo "mas apps may need an App Store sign-in - re-run this script later to finish"
fi

###############################
# Create ~/.config if missing #
###############################

mkdir -p "$HOME/.config"

#################
# Stow dotfiles #
#################

cd "$HOME/.dotfiles"

echo "Stowing dotfiles..."

if ! command -v stow &>/dev/null; then
	echo "stow not found - brew bundle may have failed earlier"
	echo "Installing stow..."
	brew install stow
fi

for pkg in zsh starship herdr git nvim zed ghostty opencode; do
	stow "$pkg"
done

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

echo "Bootstrap complete!"
echo "Open a new terminal (or run: source ~/.zshrc) to pick up PATH changes"

