#!/usr/bin/env bash
# Installs Docker, Docker Compose, jq, Go, Git and downloads Fabric binaries,
# docker images and fabric-samples into $HOME. Ubuntu 20.04 / 22.04 / 24.04.
# Run ONCE, with internet access:   bash backup_if_needed_auto/00_install_prereqs.sh
set -euo pipefail

GO_VERSION="${GO_VERSION:-1.23.4}"
FABRIC_VERSION="${FABRIC_VERSION:-}"     # empty = whatever install-fabric.sh defaults to (recommended)

echo ">>> Installing OS packages"
sudo apt-get update -y
sudo apt-get install -y curl git jq python3 ca-certificates gnupg lsb-release xxd

if ! command -v docker >/dev/null; then
  echo ">>> Installing Docker"
  sudo apt-get install -y docker.io docker-compose-v2 2>/dev/null || sudo apt-get install -y docker.io docker-compose
  sudo systemctl enable --now docker
fi
if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null; then
  sudo apt-get install -y docker-compose-v2 2>/dev/null || sudo apt-get install -y docker-compose-plugin 2>/dev/null || sudo apt-get install -y docker-compose
fi
sudo usermod -aG docker "$USER" || true

if ! command -v go >/dev/null || ! go version | grep -qE 'go1\.(2[1-9]|[3-9][0-9])'; then
  echo ">>> Installing Go $GO_VERSION"
  ARCH="$(dpkg --print-architecture)"        # amd64 / arm64
  curl -fsSLo /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tgz
  grep -q '/usr/local/go/bin' "$HOME/.profile" 2>/dev/null || echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
  export PATH="$PATH:/usr/local/go/bin"
fi
go version

cd "$HOME"
if [ ! -d "$HOME/fabric-samples" ] || [ ! -x "$HOME/fabric-samples/bin/peer" ]; then
  echo ">>> Downloading Fabric binaries, docker images and fabric-samples"
  curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/backup_if_needed_auto/install-fabric.sh
  chmod +x install-fabric.sh
  if [ -n "$FABRIC_VERSION" ]; then
    ./install-fabric.sh --fabric-version "$FABRIC_VERSION" docker samples binary
  else
    ./install-fabric.sh docker samples binary
  fi
else
  echo ">>> fabric-samples already present - skipping download"
fi

echo
echo "DONE. IMPORTANT: log out and log back in (or run 'newgrp docker') so Docker works without sudo,"
echo "then run:  bash backup_if_needed_auto/01_start_network.sh"
