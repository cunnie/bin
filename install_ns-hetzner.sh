#!/bin/bash -x

# This script is meant to be an idempotent script (you can run it multiple
# times in a row).

# This script is meant to be run by the root user
# terraform's custom_data) with no ssh key, no USER or HOME variable, and also
# be run by user cunnie, with ssh keys and environment variables set.

# to troubleshoot: ssh ubuntu@ns-hetzner

# Output is in /var/log/cloud-init-output.log

set -xeu -o pipefail

# Source common functions
source "$(dirname "$0")/install_common.sh"

create_user_cunnie() {
  if ! id cunnie; then
    sudo adduser \
      --shell=/usr/bin/zsh \
      --gecos="Brian Cunnie" \
      --disabled-password \
      cunnie
    for GROUP in root adm sudo www-data; do
      sudo adduser cunnie $GROUP
    done
    echo "cunnie ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-cunnie
    sudo mkdir -p ~cunnie/.ssh
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWiAzxc4uovfaphO0QVC2w00YmzrogUpjAzvuqaQ9tD cunnie@nono.io " | sudo tee -a ~cunnie/.ssh/authorized_keys
    ssh-keyscan github.com | sudo tee -a ~cunnie/.ssh/known_hosts
    sudo touch ~cunnie/.zshrc
    sudo chmod -R go-rwx ~cunnie/.ssh
    sudo git clone https://github.com/cunnie/bin.git ~cunnie/bin
    sudo chown -R cunnie:cunnie ~cunnie
  fi
}

id # Who am I? for debugging purposes
START_TIME=$(date +%s)
ARCH=$(uname -m)
export HOSTNAME=$(hostname)
install_packages
configure_sudo
create_user_cunnie
use_pacific_time
rsyslog_ignores_sslip

if id -u cunnie && [ $(id -u) == $(id -u cunnie) ]; then
  configure_git
  mkdir -p $HOME/workspace # sometimes run as root via terraform user_data, no HOME
  configure_zsh          # needs to come before install steps that modify .zshrc
  install_chruby
  install_zsh_autosuggestions
  configure_direnv
  install_p10k
  configure_ntp
  install_sslip_io_dns
  install_sslip_io_web # installs HTTP only
  install_tls # gets certs & updates nginx to include HTTPS
  delete_adminuser # install includes jjan ubuntu user; delete it
fi
echo "It took $(( $(date +%s) - START_TIME )) seconds to run"
