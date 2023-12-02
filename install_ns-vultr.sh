#!/usr/local/bin/zsh
set -eux -o pipefail

install_packages() {
  sudo pkg install -y \
    bash \
    bind918 \
    fasd \
    git \
    neovim \
    sudo \
    zsh \

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
    touch ~cunnie/.ssh/known_hosts
    chmod -R go-rwx ~cunnie/.ssh
    chown -R cunnie:cunnie ~cunnie/.ssh
    # pre-populate GitHub key to sidestep dialogue  "The authenticity of host ...can't be established."
    cat > ~cunnie/.ssh/known_hosts <<EOF
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
EOF
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
    echo 'eval "$(fasd --init posix-alias zsh-hook)"' >> ~cunnie/.zshrc
    echo "alias z='fasd_cd -d'" >> ~cunnie/.zshrc
    echo 'export EDITOR=nvim' >> ~cunnie/.zshrc
    echo "# Don't log me out of LastPass for 10 hours" >> ~cunnie/.zshrc
    echo 'export LPASS_AGENT_TIMEOUT=36000' >> ~cunnie/.zshrc
  fi
}

configure_bind() {
  if ! sudo grep -q nono.io /etc/named.conf; then
    sudo sed -i 's/listen-on port 53.*/listen-on port 53 { any; };/;
      s/listen-on-v6 port 53.*/listen-on-v6 port 53 { any; };/;
      s/allow-query.*/allow-query     { any; }; allow-query-cache { any; };/' /etc/named.conf
    sudo tee -a /etc/named.conf << EOF
zone "9.0.10.in-addr.arpa" {
	type slave;
	file "9.0.10.in-addr.arpa";
	masters {
		2601:646:100:69f0::a; // atom.nono.io
	};
};
zone "nono.io" {
	type slave;
	file "nono.io";
	masters {
		2a01:4f8:c17:b8f::2; //shay.nono.io
	};
};
EOF
    sudo systemctl enable named-chroot
    sudo systemctl start named-chroot
  fi
}

install_packages
configure_passwordless_sudo
adduser_cunnie
configure_git
configure_zsh          # needs to come before install steps that modify .zshrc
exit
configure_bind
