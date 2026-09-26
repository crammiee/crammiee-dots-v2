# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Layout

Everything is managed on a normal Arch machine with a display. On WSL, the
GUI-only configs are skipped automatically — see `.chezmoiignore`, which
detects WSL via `.chezmoi.kernel.osrelease` containing `microsoft`.

| Scope | Files |
|-------|-------|
| Shared | `.zshrc`, `.tmux.conf`, `.config/{nvim,yazi}/`, `.local/bin/pdf2md` |
| GUI only | `.zprofile`, `.config/{sway,foot,fuzzel,i3status-rust,gtk-3.0,gtk-4.0,nwg-look}`, `.config/mimeapps.list`, `.local/bin/{wifi-menu,firefox-toggle,firefox-prewarm}` |

Deliberately **not** tracked: `.config/gh` (auth tokens), plus caches and
runtime state (`pulse`, `systemd`, `procps`, `mozilla`).

## New machine

```sh
# 1. Bootstrap: just enough to clone. `chezmoi apply` installs the rest.
sudo pacman -S --needed chezmoi git

# 2. Clone + apply the dotfiles
chezmoi init --apply --source ~/dev/dotfiles https://github.com/crammiee/crammiee-dots-v2

# 3. Tell chezmoi where the repo lives (init does NOT save this)
mkdir -p ~/.config/chezmoi
echo 'sourceDir = "~/dev/dotfiles"' > ~/.config/chezmoi/chezmoi.toml

# 4. Sanity check — empty output means $HOME matches the repo
chezmoi status
```

`--apply` clones and applies in one step. Before writing any files, it runs
`run_onchange_before_install-packages.sh.tmpl`, which installs everything in
`.chezmoidata/packages.yaml` (asks for your `sudo` password). On WSL the GUI
packages and configs are both skipped automatically — no extra flags needed.

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

Listed in `.chezmoidata/packages.yaml`: `shared` goes on every machine,
`gui` only on machines with a display (skipped on WSL, same check as
`.chezmoiignore`). `swaynag` ships with `sway`.

AUR packages go under `aur.shared` / `aur.gui` and are installed with `yay`
(or `paru`). If neither is installed, the script bootstraps `yay-bin` first
(pulls in `base-devel`).

To add one, append it to the right list and run `chezmoi apply`. The install
script is a `run_onchange_` script, so chezmoi re-runs it only when its
rendered contents change — i.e. when a list changes. `--needed` skips
whatever is already installed. Removing a package from the list does **not**
uninstall it; do that with `pacman -Rns` yourself.

The `.zshrc` guards its plugin sourcing, so a machine missing any of the
shared packages still gets a working shell.

Neovim's Mason installs LSPs/linters with `npm` and `unzip`, and the clipboard
needs `wl-clipboard` (WSLg speaks Wayland too). On WSL these matter extra:
without a Linux `node`/`npm`, Mason silently picks up the **Windows** `npm`
from the appended Windows `PATH`, and the resulting tools fail with `EACCES`.
If that already happened, install the packages, then
`rm -rf ~/.local/share/nvim/mason/{packages,bin,share,opt}` and let Mason reinstall.
