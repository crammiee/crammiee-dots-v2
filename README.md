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
# 1. Packages (shared — needed on every machine)
sudo pacman -S chezmoi zsh zsh-autosuggestions zsh-syntax-highlighting \
  zoxide starship neovim git tmux

# 1b. GUI machines only — skip on WSL
sudo pacman -S sway swaybg swayidle swaylock foot fuzzel \
  i3status-rust brightnessctl playerctl pipewire pipewire-pulse \
  pipewire-alsa wireplumber networkmanager tlp autotiling

# 2. Clone + apply the dotfiles
chezmoi init --apply --source ~/dev/dotfiles https://github.com/crammiee/crammiee-dots-v2

# 3. Tell chezmoi where the repo lives (init does NOT save this)
mkdir -p ~/.config/chezmoi
echo 'sourceDir = "~/dev/dotfiles"' > ~/.config/chezmoi/chezmoi.toml

# 4. Sanity check — empty output means $HOME matches the repo
chezmoi status
```

`--apply` clones and applies in one step. On WSL the GUI configs are skipped
automatically — no extra flags needed for that.

`--source` keeps the repo at `~/dev/dotfiles` instead of chezmoi's default
(`~/.local/share/chezmoi`), so it's easy to `cd` into. But the flag only
applies to that one command — it is **not** persisted. Without step 3, every
later `chezmoi` command fails with
`stat ~/.local/share/chezmoi: no such file or directory`. The
`chezmoi.toml` is machine-local config and is *not* tracked by chezmoi itself.

After install, if zsh isn't already your login shell: `chsh -s /bin/zsh`.
Neovim (LazyVim) installs its plugins on first launch.

## Installing these on someone else's machine

`chezmoi apply` **overwrites** existing dotfiles, so don't blind-apply a
stranger's config. Preview first:

```sh
pacman -S chezmoi
chezmoi init <this-repo-url>   # clone only, changes nothing yet
chezmoi diff                   # see exactly what would be overwritten
chezmoi apply                  # commit to it once you're happy
```

Take individual pieces instead of everything:

```sh
chezmoi apply ~/.config/sway   # just this one path
```

Things that are **not** carried over, because they aren't dotfiles:

- TLP battery charge thresholds (`/etc/tlp.d/`, root-owned)
- Enabled systemd user services (`pipewire`, `wireplumber`)
- Installed packages (see below)

## Settings GUI

`$mod+Shift+S` opens a fuzzel menu that launches a focused tool per domain,
rather than one monolithic settings app:

| Entry | Tool |
|-------|------|
| Audio | `pavucontrol` |
| Displays | `nwg-displays` |
| Appearance | `nwg-look` |
| Network | `nm-connection-editor` |
| Wi-Fi | `~/.local/bin/wifi-menu` |

**These GUIs write to chezmoi-managed files.** `nwg-look` writes
`~/.config/gtk-3.0/settings.ini`; `nwg-displays` writes a sway output
include. Treat them as *generators*: after changing something in a GUI,

```sh
chezmoi add ~/.config/gtk-3.0/settings.ini
```

and commit — otherwise the next `chezmoi apply` reverts it.

## Changing something

Two directions, depending on where you made the edit.

**Edited the real file directly** (e.g. tweaked `~/.config/sway/config`) —
pull the change back into the repo:

```sh
chezmoi add ~/.config/sway/config   # re-add = capture current contents
chezmoi cd                          # into ~/dev/dotfiles
git add -A && git commit -m "sway: ..." && git push
exit
```

**Edited via chezmoi** — writes to the repo, then pushes out to `$HOME`:

```sh
chezmoi edit ~/.config/sway/config   # opens the source file in nvim
chezmoi diff                         # preview
chezmoi apply                        # write it out to $HOME
```

**On your other machine**, pull the changes down:

```sh
chezmoi update    # git pull + apply in one step
```

Useful checks:

```sh
chezmoi status    # empty output = $HOME matches the repo
chezmoi managed   # list every file chezmoi controls
chezmoi doctor    # sanity-check the setup
```

## Packages

Not installed by chezmoi — see the `pacman` commands under **New machine**.
(`swaynag` ships with `sway`.)

- Shared: `zsh zsh-autosuggestions zsh-syntax-highlighting zoxide starship neovim git tmux`
- GUI only: `sway swaybg swayidle swaylock foot fuzzel i3status-rust brightnessctl playerctl pipewire pipewire-pulse pipewire-alsa wireplumber networkmanager tlp autotiling`

The `.zshrc` guards its plugin sourcing, so a machine missing any of the
shared packages still gets a working shell.
