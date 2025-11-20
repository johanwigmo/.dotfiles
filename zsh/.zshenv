export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

DOTFILES_ENV="$HOME/.config/dotfiles.env"
if [ -f "$DOTFILES_ENV" ]; then
	source "$DOTFILES_ENV"
fi
