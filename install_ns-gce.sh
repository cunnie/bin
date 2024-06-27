#!/bin/bash -x
set -xeu -o pipefail

install_packages() {
  sudo dnf groupinstall -y "Development Tools"
  sudo dnf remove -y chrony
  sudo dnf install -y \
    binutils \
    btrfs-progs \
    cmake \
    cronie \
    direnv \
    dnf-plugins-core \
    fd-find \
    gcc-g++ \
    git \
    git-lfs \
    golang \
    golang-x-tools-gopls \
    htop \
    iproute \
    iputils \
    jq \
    lastpass-cli \
    libxml2-devel \
    libcurl-devel \
    mysql-devel \
    neovim \
    net-tools \
    nmap-ncat \
    npm \
    ntpsec \
    openssl-devel \
    postgresql-devel \
    python3-pip \
    redhat-rpm-config \
    ripgrep \
    ruby \
    ruby-devel \
    rubygems \
    socat \
    strace \
    tcpdump \
    tmux \
    util-linux-user \
    wget \
    zlib-devel \
    zsh \
    zsh-lovers \
    zsh-syntax-highlighting \

}

install_chruby() {
  if [ ! -d /usr/local/share/chruby ] ; then
    wget -O ruby-install-0.9.3.tar.gz \
      https://github.com/postmodern/ruby-install/releases/download/v0.9.3/ruby-install-0.9.3.tar.gz
    tar -xzvf ruby-install-0.9.3.tar.gz
    cd ruby-install-0.9.3/
    sudo make install

    wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
    tar -xzvf chruby-0.3.9.tar.gz
    cd chruby-0.3.9/
    sudo make install
    cat >> $HOME/.zshrc <<EOF

source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh
EOF
  fi
}

install_fasd() {
  if [ ! -x /usr/local/bin/fasd ]; then
    cd ~/workspace
    git clone git@github.com:clvv/fasd.git
    cd fasd
    sudo make install
    cat >> ~/.zshrc <<EOF

eval "\$(fasd --init posix-alias zsh-hook)"
alias z='fasd_cd -d'     # cd, same functionality as j in autojump
EOF
  fi
}

install_bin() {
  if [ ! -d $HOME/bin ]; then
    git clone git@github.com:cunnie/bin.git $HOME/bin
    echo 'PATH="$HOME/bin:$PATH:/usr/local/go/bin"' >> ~/.zshrc
    ln -s ~/bin/env/git-authors ~/.git-authors
  fi
}


install_terraform() {
  if [ ! -x /usr/local/bin/terraform ]; then
    curl -o tf.zip -L https://releases.hashicorp.com/terraform/1.6.3/terraform_1.6.3_linux_amd64.zip
    unzip tf.zip
    sudo install terraform /usr/local/bin/
  fi
}

install_zsh_autosuggestions() {
  if [ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
      sed -i 's/^plugins=(/&zsh-autosuggestions /' $HOME/.zshrc
  fi
}

install_git_duet() {
  if [ ! -x /usr/local/bin/git-duet ]; then
    mkdir -p /tmp/$$/git-duet
    pushd /tmp/$$
    curl -o git-duet.tgz -L https://github.com/git-duet/git-duet/releases/download/0.9.0/linux_amd64.tar.gz
    tar -xzvf git-duet.tgz -C git-duet/
    sudo install git-duet/* /usr/local/bin
    popd
  fi
}

configure_direnv() {
  if ! grep -q "direnv hook zsh" ~/.zshrc; then
    echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
    eval "$(direnv hook bash)"
  fi
  for envrc in $(find "$HOME/workspace" -maxdepth 2 -name '.envrc' -print); do
    pushd $(dirname $envrc)
      direnv allow
    popd
  done
}

configure_zsh() {
  if [ ! -f $HOME/.zshrc ]; then
    sudo chsh -s /usr/bin/zsh $USER
    echo "" | SHELL=/usr/bin/zsh zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sed -i 's/robbyrussell/agnoster/' ~/.zshrc
    echo 'eval "$(fasd --init posix-alias zsh-hook)"' >> ~/.zshrc
    echo 'export EDITOR=nvim' >> ~/.zshrc
    echo 'alias k=kubectl' >> ~/.zshrc
    echo "# Don't log me out of LastPass for 10 hours" >> ~/.zshrc
    echo 'export LPASS_AGENT_TIMEOUT=36000' >> ~/.zshrc
    echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True # fixes "WARNING: the gcp auth plugin is deprecated in v1.22+, unavailable in v1.25+;' >> ~/.zshrc
    echo '. $HOME/.venv/base/bin/activate' >> ~/.zshrc
  fi
}

use_pacific_time() {
  sudo timedatectl set-timezone America/Los_Angeles
}

configure_git() {
  # https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases
  git config --global user.name "Brian Cunnie"
  git config --global user.email brian.cunnie@gmail.com
  git config --global alias.co checkout
  git config --global alias.ci commit
  git config --global alias.st status
  git config --global url."git@github.com:".insteadOf "https://github.com/"
  git config --global color.branch auto
  git config --global color.diff auto
  git config --global color.status auto
  git config --global core.editor nvim
}

configure_tmux() {
  # https://github.com/luan/tmuxfiles, to clear, `rm -rf ~/.tmux.conf ~/.tmux`
  if [ ! -f $HOME/.tmux.conf ]; then
    echo "WARNING: If this scripts fails with \"unknown variable: TMUX_PLUGIN_MANAGER_PATH\""
    echo "If you don't have an ugly magenta bottom of your tmux screen, if nvim is unusable, then"
    echo "you may need to run this command to completely install tmux configuration:"
    echo "zsh -c \"\$(curl -fsSL https://raw.githubusercontent.com/luan/tmuxfiles/master/install)\""
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/luan/tmuxfiles/master/install)"
  fi
}

disable_firewalld() {
  # so that BIND can work
  sudo systemctl stop firewalld || true
  sudo systemctl disable firewalld || true
}

configure_passwordless_sudo() {
  SUDO_FILE=/etc/sudoers.d/passwordless
  if ! sudo test -f $SUDO_FILE ; then
    sudo tee $SUDO_FILE <<EOF
# Ubuntu: Allow members of group sudo  to execute any command
%sudo  ALL=(ALL) NOPASSWD: ALL
# Fedora: Allow members of group wheel to execute any command
%wheel ALL=(ALL) NOPASSWD: ALL
EOF
  fi
}

configure_python_venv() {
  VENV_DIR=$HOME/.venv/base
  if [ ! -d $VENV_DIR ]; then
    python3 -m venv $VENV_DIR
    source $VENV_DIR/bin/activate
  fi
}

fix_partitions() {
  sudo parted --fix /dev/sda print
  # Thanks Sunil Mohan https://bugs.launchpad.net/ubuntu/+source/parted/+bug/1270203/comments/6
  echo -e "yes\n100%" | sudo parted /dev/sda ---pretend-input-tty unit % resizepart 5
  sudo parted --fix /dev/sda print
  sudo btrfs filesystem resize max /
}

install_sslip_io_dns() {
  if [ ! -x /usr/bin/sslip.io-dns-server ]; then
    GOLANG_ARCH=$ARCH
    GOLANG_ARCH=${GOLANG_ARCH/aarch64/arm64}
    GOLANG_ARCH=${GOLANG_ARCH/x86_64/amd64}
    curl -L https://github.com/cunnie/sslip.io/releases/download/3.1.0/sslip.io-dns-server-linux-$GOLANG_ARCH \
      -o sslip.io-dns-server
    sudo install sslip.io-dns-server /usr/bin
    sudo curl -L https://raw.githubusercontent.com/cunnie/deployments/master/terraform/aws/sslip.io-vm/sslip.io.service \
      -o /etc/systemd/system/sslip.io-dns.service
    sudo systemctl daemon-reload
    sudo systemctl enable sslip.io-dns
    sudo systemctl start sslip.io-dns
  fi
}

rsyslog_ignores_sslip() {
  RSYSLOG_CONFIG=/etc/rsyslog.d/10-sslip.io.conf
  if [ ! -f $RSYSLOG_CONFIG ]; then
    sudo tee -a $RSYSLOG_CONFIG <<EOF
# sslip.io-dns-server is too verbose, consumed 15G in /var/log
# rely only on journalctl henceforth
:programname, isequal, "sslip.io-dns-server" stop
EOF
    sudo systemctl restart rsyslog
  fi
}

configure_ntp() {
  if ! grep -q time1.google.com /etc/ntp.conf; then
    cat <<EOF | sudo tee /etc/ntp.conf
# Our upstream timekeepers; thank you Google
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
# "Batten down the hatches!"
# see http://support.ntp.org/bin/view/Support/AccessRestrictions
restrict default limited kod nomodify notrap nopeer
restrict -6 default limited kod nomodify notrap nopeer
restrict 127.0.0.0 mask 255.0.0.0
restrict -6 ::1
EOF
    sudo systemctl enable ntpd
    sudo systemctl start ntpd
  fi
}

id # Who am I? for debugging purposes
START_TIME=$(date +%s)
ARCH=$(uname -m) # `uname -i` returns "unknown" on GCP
export HOSTNAME=$(hostname)
fix_partitions
install_packages
use_pacific_time
disable_firewalld
rsyslog_ignores_sslip

if id -u cunnie && [ $(id -u) == $(id -u cunnie) ]; then
  mkdir -p ~/workspace
  configure_zsh          # needs to come before install steps that modify .zshrc
  install_bin
  install_chruby
  install_fasd
  install_git_duet
  install_terraform
  install_zsh_autosuggestions
  install_sslip_io_dns
  configure_ntp
  configure_direnv
  configure_git
  configure_tmux
  configure_passwordless_sudo
  configure_python_venv
fi
