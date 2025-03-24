#!/usr/local/bin/zsh
set -eux -o pipefail

install_packages() {
  pkg install -y \
    bash \
    bind918 \
    dhcp6 \
    dhcpd \
    fasd \
    git \
    htop \
    iperf3 \
    neovim \
    rsync \
    ruby \
    sudo \
    tmux \
    wireguard-tools \
    zsh \
    zsh-autosuggestions \

}

configure_git() {
  for ACCOUNT in root cunnie; do
    # https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases
    sudo -u $ACCOUNT git config --global user.name "Brian Cunnie"
    sudo -u $ACCOUNT git config --global user.email brian.cunnie@gmail.com
    sudo -u $ACCOUNT git config --global alias.co checkout
    sudo -u $ACCOUNT git config --global alias.ci commit
    sudo -u $ACCOUNT git config --global alias.st status
    sudo -u $ACCOUNT git config --global color.branch auto
    sudo -u $ACCOUNT git config --global color.diff auto
    sudo -u $ACCOUNT git config --global color.status auto
    sudo -u $ACCOUNT git config --global core.editor nvim
  done
}

adduser_cunnie() {
  if ! id cunnie; then
    adduser \
      -G wheel \
      -s /usr/local/bin/zsh \
      -w random \
      -f <(echo "cunnie::::::Brian Cunnie::/usr/local/bin/zsh:")
    mkdir -p ~cunnie/.ssh
    # pre-populate GitHub key to sidestep dialogue  "The authenticity of host ...can't be established."
    cat > ~cunnie/.ssh/known_hosts <<EOF
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
EOF
    cat > ~cunnie/.ssh/authorized_keys <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWiAzxc4uovfaphO0QVC2w00YmzrogUpjAzvuqaQ9tD cunnie@nono.io
EOF
    chmod -R go-rwx ~cunnie/.ssh
    chown -R cunnie:cunnie ~cunnie/.ssh
  fi
}

configure_passwordless_sudo() {
  SUDO_FILE=/usr/local/etc/sudoers.d/passwordless
  if ! sudo test -f $SUDO_FILE ; then
    sudo tee $SUDO_FILE <<EOF
# Ubuntu: Allow members of group sudo  to execute any command
%sudo  ALL=(ALL) NOPASSWD: ALL
# Fedora, FreeBSD: Allow members of group wheel to execute any command
%wheel ALL=(ALL) NOPASSWD: ALL
EOF
  fi
}

configure_zsh() {
  if [ ! -f ~cunnie/.zshrc ]; then
    echo "" | sudo -u cunnie zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sed -i '' 's/robbyrussell/agnoster/' ~cunnie/.zshrc
    echo "source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~cunnie/.zshrc
    echo 'eval "$(fasd --init posix-alias zsh-hook)"' >> ~cunnie/.zshrc
    echo "alias z='fasd_cd -d'" >> ~cunnie/.zshrc
    echo 'export EDITOR=nvim' >> ~cunnie/.zshrc
    echo 'export GIT_DISCOVERY_ACROSS_FILESYSTEM=1' >> ~cunnie/.zshrc
  fi
}

[ $(id -u) = 0 ] || ( echo "I need to be run as root"; exit 1 )
install_packages
configure_passwordless_sudo
adduser_cunnie
configure_git
configure_zsh
sudo chown -R cunnie:cunnie ~cunnie
