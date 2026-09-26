# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Layout

Everything is managed on a normal Arch machine with a display. On WSL, the
GUI-only configs are skipped automatically — see `.chezmoiignore`, which
detects WSL via `.chezmoi.kernel.osrelease` containing `microsoft`.

| Scope | Files |
|-------|-------|
| Shared | `.zshrc`, `.tmux.conf`, `.config/{nvim,yazi}/`, `.local/bin/pdf2md` |
| GUI only | `.zprofile`, `.config/{sway,foot,fuzzel,i3status-rust,gtk-3.0,gtk-4.0,nwg-look}`, `.config/mimeapps.list`, `.local/bin/{wifi-menu,firefox-toggle,firefox-prewarm,settings-menu,claude-inhibit-watch,swayidle-launcher,idle-timeout-menu}` |

Deliberately **not** tracked: `.config/gh` (auth tokens), plus caches and
runtime state (`pulse`, `systemd`, `procps`, `mozilla`).

## Setting up a machine

Pick the section for the machine, then both end in
[**Applying the dotfiles**](#applying-the-dotfiles). The same repo serves
both; WSL just gets the shared configs and packages.

### New Arch laptop

Starting point: a minimal Arch install, rebooted and logged in as root on the
TTY. Include NetworkManager at install time, or the new system has no Wi-Fi:
`pacstrap /mnt base linux linux-firmware networkmanager`, or in `archinstall`
pick the **Minimal** profile and **NetworkManager** under Network
configuration. Everything past what's below comes from
`.chezmoidata/packages.yaml`, including `base-devel` and the
whole desktop.

```sh
# 1. Network
systemctl enable --now NetworkManager
nmcli device wifi connect "<SSID>" --ask    # or: nmtui

# 2. Update, and get sudo for the user
pacman -Syu --needed sudo zsh
useradd -m -G wheel -s /bin/zsh <user>
passwd <user>
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel   # base has no editor for visudo
chmod 440 /etc/sudoers.d/wheel

# 3. Log out, log back in as <user>, then do "Applying the dotfiles" below.
```

After **Applying the dotfiles** finishes:

```sh
# 4. Battery tuning (pipewire's user units are socket-activated, nothing to enable)
sudo systemctl enable --now tlp

# 5. Optional: keep the laptop awake while `claude` runs. The unit file is
#    deliberately untracked (see CLAUDE.md), so create it by hand:
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/claude-inhibit.service <<'EOF'
[Unit]
Description=Hold a sleep inhibitor while any claude process is running

[Service]
ExecStart=%h/.local/bin/claude-inhibit-watch
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
systemctl --user enable --now claude-inhibit.service

# 6. Things not in the repo
mkdir -p ~/Pictures/wallpapers    # copy spiderman.jpg here, or sway shows no wallpaper

# 7. Reboot. Logging in on tty1 starts sway (.zprofile).
sudo reboot
```

Wi-Fi after that: `$mod+Shift+S` → **Wi-Fi**, or `nmtui`.

### New WSL machine

From PowerShell, install the official Arch image. It opens a root shell and
sets up the pacman keyring on first launch.

```powershell
wsl --install archlinux
```

Then inside it, as root:

```sh
# 1. Update, and get sudo for the user
pacman -Syu --needed sudo zsh
useradd -m -G wheel -s /bin/zsh <user>
passwd <user>
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# 2. Log in as <user> by default instead of root
printf '\n[user]\ndefault=<user>\n' >> /etc/wsl.conf
```

```powershell
# 3. Restart the distro so wsl.conf takes effect, then reopen it
wsl --terminate archlinux
wsl -d archlinux
```

Now do **Applying the dotfiles** below. Nothing else needed afterwards: no
sway, services or wallpaper on WSL, and the clipboard works through WSLg.
For the prompt's icons, set a Nerd Font in Windows Terminal (the font lives on
the Windows side, not in WSL).

### Applying the dotfiles

Same on both machines. On an existing machine that already has a user, this
is the only part you need.

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

### Switching the remote to SSH

`chezmoi init` clones over https because a fresh machine has no SSH key yet
(the repo is public, so no login is needed to clone). Pushing over https would
ask for a token, so once the machine has a key, switch the remote:

```sh
# 1. Make a key (skip if you restored ~/.ssh from another machine)
ssh-keygen -t ed25519 -C "<you>@<machine>"
cat ~/.ssh/id_ed25519.pub   # add at github.com -> Settings -> SSH and GPG keys

# 2. Check GitHub accepts it -- should greet you by username
ssh -T git@github.com

# 3. Point the dotfiles repo at SSH
git -C ~/dev/dotfiles remote set-url origin git@github.com:crammiee/crammiee-dots-v2.git
git -C ~/dev/dotfiles remote -v
```

`chezmoi update` just runs git in `~/dev/dotfiles`, so it uses SSH from then on
too.

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
`.chezmoiignore`, both via `.chezmoitemplates/is-wsl`). `swaynag` ships with `sway`.

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
