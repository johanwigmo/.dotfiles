# Dotfiles

My macOS environment setup.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/johanwigmo/.dotfiles.git ~/.dotfiles.git
cd ~/.dotfiles

# Make bootstrap executable (if needed)
chmod +x scripts/bootstrap.sh scripts/update.sh

# Run the setup
./scripts/bootstrap.sh
```

## bootstrap.sh

The bootstrap script will:
- Install Xcode Command Line Tools
- Install Homebrew
- Install all applications and CLI tools from Brewfile
- Set up dotfiles using GNU Stow
- Install Tmux Plugin Manager
- Configure macOS defaults

The script is idempotent and safe to re-run.

## update.sh

The update sript will:
- Pull latest dotfiles from git
- Update Homebrew packages
- Update Tmux plugins

## Manual Configuration

Some setup require manual configuration after bootstrap:

### Xcode 

- **Install Xcode** from App Store
- After installation: 

```bash
# Point xcode-select to full Xcode
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Accept license
sudo xcodebuild -license accept

# Install additional components
sudo xcodebuild -runFirstLaunch
```

### Keyboard Setup

- **Input Sources**: System Settings > Keyboard > Input Sorces
    - Add "ABC Extended"
    - Add "Swedish"
- **Caps Lock > Escapce**: System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys
    - Select "Built-in keyboard"
    - Set Caps Lock to Escape

### Accessibility

- **Zoom with scroll gestures**: System Settings -> Accessibility > Zoom
    - Enable "Use scroll gesture with modifier keys to zoom"

## Troubleshooting

### Symlinks broken 

Re-tow the configuration: 

```bash
cd ~/.dotfiles
stow -R [tool] # e.g., stow -R zsh
```

### Tmux plugins not loading

Install TPM Manually: 
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then press `prefix + I` in tmux to install plugins.

