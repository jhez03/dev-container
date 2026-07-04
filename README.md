# devbox — portable terminal dev environment

Neovim (LazyVim) + tmux + lazygit + git tooling, in a container. Configs come from a
separate [dotfiles](../dotfiles) repo cloned at image build time.

## One-time setup

1. Install Docker (Docker Desktop + WSL2 integration, or Docker Engine in WSL). Verify:
   ```bash
   docker --version && docker compose version
   ```
2. Push your `dotfiles` repo to GitHub, then set its URL:
   ```bash
   cp .env.example .env      # edit DOTFILES_REPO and PROJECTS_DIR
   ```
3. Create `~/.gitconfig.local` on the host with just your identity (and any
   host-specific `safe.directory` entries) — the shared, non-identifying git
   settings already live in `dotfiles/git/gitconfig` and get symlinked in:
   ```gitconfig
   [user]
       name = Your Name
       email = you@example.com
   ```
4. Build the image (clones dotfiles, installs plugins + LSPs):
   ```bash
   docker compose build
   ```

## Daily use

```bash
docker compose up -d           # start the container (background)
docker compose exec dev tmux   # enter tmux; run nvim / lazygit inside
docker compose down            # stop it when done
```

## After changing configs

Push to the dotfiles repo, then rebuild. Plugin data lives in a named volume, so rebuilds
are fast:
```bash
docker compose build && docker compose up -d
```

## Notes / gotchas

- **Runtimes**: editor-only base (Node included for LSPs/Copilot; Python for djlint).
  `pint` (PHP formatter) is intentionally excluded — add PHP + Composer to the `Dockerfile`
  if you need it.
- **Clipboard**: yanks reach the host via OSC52 (nvim ≥0.10). If copy/paste to Windows
  doesn't work, enable an OSC52 clipboard provider in `nvim/lua/config/options.lua`.
- **Colors look off?** Add `set -ga terminal-overrides ",*:Tc"` to your `tmux.conf`.
- **Auth**: `~/.ssh` and `~/.config/intelephense` (your license) are mounted read-only.
  `~/.gitconfig` itself comes from `dotfiles/git/gitconfig` (symlinked at build time);
  only your identity/host-specific overrides come from the host, via
  `~/.gitconfig.local` (mounted read-only, gitignored, never committed). Copilot/Claude
  Code: authenticate once inside the container via the terminal device-code flow. To
  avoid re-auth on rebuild, uncomment the `github-copilot` mount in `docker-compose.yml`.
- **Architecture**: image assumes x86_64 (correct for WSL2 on Windows). For ARM, swap the
  `nvim`/`lazygit` asset names in the `Dockerfile`.
