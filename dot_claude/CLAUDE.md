# Dotfiles are managed by chezmoi

Config files in `$HOME` are **chezmoi-managed**. The source of truth is the git
repo at `~/dev/dotfiles` (not chezmoi's default `~/.local/share/chezmoi`).

Editing a managed file in place is fine, but the change is **not saved** until
it's pulled back into the source repo — the next `chezmoi apply` will revert it
otherwise.

## After editing any managed file

```sh
chezmoi add <the-file-you-edited>     # pull the change into the source repo
cd ~/dev/dotfiles && git add -A && git commit -m "..."
```

Check `chezmoi managed | grep <path>` if unsure whether a file is managed.
Empty output from `chezmoi status` means `$HOME` and the repo agree.

## What's managed

- Shared (all machines): `.zshrc`, `.tmux.conf`, `.config/nvim/`, `.local/bin/pdf2md`,
  `.claude/CLAUDE.md`
- GUI only (skipped on WSL): `.zprofile`, `.config/{sway,foot,fuzzel,i3status-rust,gtk-3.0,gtk-4.0,nwg-look}`,
  `.config/mimeapps.list`,
  `.local/bin/{wifi-menu,firefox-toggle,firefox-prewarm,settings-menu,claude-inhibit-watch,idle-timeout-menu,swayidle-launcher}`

`.chezmoiignore` skips the GUI configs on WSL by detecting `microsoft` in
`.chezmoi.kernel.osrelease`. Anything GUI-related must stay inside that block.

## Not managed on purpose

`.config/gh` (auth tokens), caches, and runtime state (`pulse`, `systemd`,
`procps`, `mozilla`). System-level config (`/etc/tlp.d/`, enabled systemd
units) is outside chezmoi entirely.

## Machine

ThinkPad X250, Arch, sway. There's a second machine running Arch on WSL that
shares this repo. Prefer lightweight, low-overhead tooling — this is an old
dual-core laptop with a degraded battery.
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
