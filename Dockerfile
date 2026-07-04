# Editor-only dev box: Neovim (LazyVim) + tmux + lazygit + git tooling + Node.
# Configs come from your dotfiles repo, cloned and installed at build time.
FROM debian:trixie-slim

# Override at build time: --build-arg DOTFILES_REPO=...
ARG DOTFILES_REPO=https://github.com/jhez03/dotfiles.git
ARG USERNAME=dev
ARG NODE_MAJOR=22

# --- base tooling --------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client build-essential unzip \
      ripgrep fd-find tmux xclip locales \
      python3 python3-pip pipx \
    && rm -rf /var/lib/apt/lists/*
# UTF-8 locale so nvim/tmux glyphs render correctly
RUN sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
# Debian ships fd as `fdfind`; expose it as `fd` for Telescope/LazyVim
RUN ln -s "$(command -v fdfind)" /usr/local/bin/fd || true

# --- Node.js (Mason: intelephense, emmet-ls) --------
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

# --- Neovim (latest stable release tarball) ---------
RUN curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
      -o /tmp/nvim.tar.gz \
    && tar -xzf /tmp/nvim.tar.gz -C /opt \
    && ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim \
    && rm /tmp/nvim.tar.gz

# --- lazygit (latest release) --------------------------------------------------
RUN LG_VER=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
      | grep -Po '"tag_name": "v\K[^"]*') \
    && curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_x86_64.tar.gz" \
      -o /tmp/lg.tar.gz \
    && tar -xzf /tmp/lg.tar.gz -C /usr/local/bin lazygit && rm /tmp/lg.tar.gz

# --- djlint (Twig linter/formatter; needs Python) ------------------------------
# RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install djlint

# --- non-root user -------------------------------------------------------------
RUN useradd -ms /bin/bash ${USERNAME}
USER ${USERNAME}
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"
WORKDIR /home/${USERNAME}

# Pre-create nvim data/state/undo dirs as `dev` so the named volumes in
# docker-compose.yml inherit dev:dev ownership when first populated.
RUN mkdir -p /home/${USERNAME}/.local/share/nvim /home/${USERNAME}/.local/state/nvim /home/${USERNAME}/.vim/undodir

# --- clone dotfiles + install (plugins/LSPs baked into the image) --------------
# Cache-bust: bump this arg to force a fresh dotfiles clone on rebuild.
ARG DOTFILES_REF=main
RUN git clone --depth 1 --branch ${DOTFILES_REF} ${DOTFILES_REPO} /home/${USERNAME}/dotfiles \
    && bash /home/${USERNAME}/dotfiles/install.sh

WORKDIR /workspace
