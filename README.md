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

## scripts/ layout

Scripts stay flat — every path here is load-bearing somewhere else
(LaunchAgent plists, repo AGENTS.md files, opencode agent permission globs,
vault skills), so subfolders mean churning all of those. Document by
consumer class instead:

| Class | Scripts | Referenced by |
|---|---|---|
| Setup/update flow | `bootstrap.sh`, `update.sh`, `install-launchagents.sh` | run by hand; bootstrap/update call the installer |
| LaunchAgent payloads | `sync-notes.sh`, `tailscale-watchdog.sh` | plists in `LaunchAgents/` (hardwired absolute paths, gated per machine in `install-launchagents.sh`) |
| Session tools | `toggl-weekly.sh` | vault skills + vault `AGENTS.md` |
| Dev helpers | `ios-build.sh`, `ios-lsp-bootstrap.sh`, `dev-project-init.sh` | repo `AGENTS.md` files (ios-build is the repos' build/test/run entry point), opencode worker permissions |

Rules:
- Treat script paths as interfaces: before renaming or moving one, grep
  this repo, the vault, and `~/Developer` repos for the old path.
- New agent-class script (`*.plist` payload) goes in `LaunchAgents/` +
  a `TAILSCALE_WATCHDOG`-style gate in `install-launchagents.sh`.
- If the directory grows enough to want subfolders, split only launchd
  payloads into `scripts/agents/` — keep hand-called scripts flat, those
  are the short paths worth keeping.

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

### Secrets

Script secrets live in `~/.config/dotfiles.env` (mode 600, gitignored). On a fresh machine, bootstrap seeds it from the tracked `config/dotfiles.env.example` — add the machine-local entries after bootstrap:

```bash
chmod 600 ~/.config/dotfiles.env
# then edit: add machine-local exports (hosts, API tokens)
```

Nothing secret is committed to this repo.

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

### Tailscale offline after running update.sh

Seen 2026-10: the `tailscale-app` cask needs admin rights, and brew quits
the running app *before* asking for the password — an unnoticed prompt
aborts the upgrade and leaves the app quit. `update.sh` therefore asks
for the password up front and makes it optional: grant sudo and
everything upgrades; skip it and the casks in `SUDO_CASKS` (update.sh)
wait for the next run *with* sudo while everything else still upgrades.
The relaunch after `brew cleanup` and the `tailscale-watchdog` agent on
the mini are the backstops.

### Symlinks broken 

Re-tow the configuration: 

```bash
cd ~/.dotfiles
stow -R [tool] # e.g., stow -R zsh
```

### Brewfile upgrades report failures

`brew bundle` can report upgrades as failed with no error text (seen with Homebrew 7's new upgrade flow). The failures are transient — each formula upgrades fine individually and `brew bundle` is idempotent, so re-run `./scripts/update.sh`. The update script also retries `brew bundle` once automatically.

If `opencode` fails with "installed from the homebrew/core tap but you are trying to install it from the anomalyco/tap", switch once manually:

```bash
brew uninstall opencode && brew install anomalyco/tap/opencode
```

(The update script detects and fixes this automatically on newer copies.)

