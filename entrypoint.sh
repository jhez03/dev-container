#!/usr/bin/env bash
# Runs as root at container start (Dockerfile no longer sets a default USER).
# Aligns `dev` with whatever group owns the host's mounted docker.sock, since
# its GID varies by host/VM, then drops to `dev` to run the real command.
set -euo pipefail

SOCKET=/var/run/docker.sock
if [ -S "$SOCKET" ]; then
  SOCK_GID=$(stat -c '%g' "$SOCKET")
  if ! getent group "$SOCK_GID" >/dev/null 2>&1; then
    groupadd -g "$SOCK_GID" docker-host
  fi
  usermod -aG "$(getent group "$SOCK_GID" | cut -d: -f1)" dev
fi

exec gosu dev "$@"
