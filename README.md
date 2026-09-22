# Dotfiles

My macOS environment setup.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/johanwigmo/.dotfiles.git ~/.dotfiles
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
- Configure macOS defaults

The script is idempotent and safe to re-run.

## update.sh

The update sript will:
- Pull latest dotfiles from git
- Re-stows configurations
- Update Homebrew packages

## Manual Configuration

Some setup require manual configuration after bootstrap. These are some of the things I need to adjust (not all, because I never remember what I have changed):

### App Store Sign-In

The Brewfile installs Toggl Track, Vimlike, and Magnet via `mas`, which requires a signed-in App Store account — sign in and re-run bootstrap/update if these were skipped.

### Xcode

Install from the App Store (or developer.apple.com for a specific version) — intentionally not in the Brewfile, since a multi-GB `mas` download can stall or abort the bootstrap. After installation:

```bash
# Point xcode-select to full Xcode
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Accept license
sudo xcodebuild -license accept

# Install additional components
sudo xcodebuild -runFirstLaunch
```

### Remote Access (SSH)

Needed for headless or remote use (Mac Mini):

```bash
sudo systemsetup -setremotelogin on
```

Or enable via: System Settings > General > Sharing > Remote Login

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

