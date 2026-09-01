# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Layout

Everything is managed on a normal Arch machine with a display. On WSL, the
GUI-only configs are skipped automatically — see `.chezmoiignore`, which
detects WSL via `.chezmoi.kernel.osrelease` containing `microsoft`.

| Scope | Files |
|-------|-------|
| Shared | `.zshrc`, `.config/nvim/` |
| GUI only | `.zprofile`, `.config/{sway,foot,fuzzel,i3status-rust,gtk-3.0,gtk-4.0}`, `.config/mimeapps.list`, `.local/bin/{wifi-menu,firefox-toggle,firefox-prewarm}` |

Deliberately **not** tracked: `.config/gh` (auth tokens), plus caches and
runtime state (`pulse`, `systemd`, `procps`, `mozilla`).

## New machine

```sh
pacman -S chezmoi
chezmoi init --apply <this-repo-url>
```

`--apply` clones and applies in one step. On WSL the GUI configs are skipped
with no extra flags or arguments needed.

## Daily use

```sh
chezmoi add <file>     # start tracking a file, or pull in local edits
chezmoi diff           # preview what apply would change
chezmoi apply          # write source state to $HOME
chezmoi cd             # shell into the source repo to commit/push
```

## Packages

Not installed by chezmoi. Roughly:

- Shared: `zsh zsh-autosuggestions zsh-syntax-highlighting zoxide starship neovim git`
- GUI only: `sway swaybg swayidle swaylock swaynag foot fuzzel i3status-rust brightnessctl playerctl pipewire pipewire-pulse pipewire-alsa wireplumber networkmanager tlp autotiling`

The `.zshrc` guards its plugin sourcing, so a machine missing any of the
shared packages still gets a working shell.
