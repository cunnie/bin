#!/bin/bash -x
set -eu -o pipefail

install_packages() {
  sudo dnf update -y
  sudo dnf install -y \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  sudo dnf groupinstall -y "Development Tools"
  sudo dnf install -y \
    binutils \
    clang \
    cmake \
    dnf-plugins-core \
    fd-find \
    fzf \
    gcc-g++ \
    git \
    git-lfs \
    htop \
    iperf3 \
    iproute \
    iputils \
    jq \
    llvm \
    neovim \
    net-tools \
    nmap-ncat \
    pciutils \
    python \
    python3-devel \
    python3-numpy \
    python3-pip \
    python3-devel \
    python3-numpy \
    qemu-kvm \
    redhat-rpm-config \
    ripgrep \
    socat \
    strace \
    tcpdump \
    tmux \
    util-linux-user \
    wget \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting

}

install_bin() {
  if [ ! -d $HOME/bin ]; then
    git clone git@github.com:cunnie/bin.git $HOME/bin
    echo 'PATH="$HOME/bin:$PATH:/usr/local/go/bin"' >> ~/.zshrc
    ln -s ~/bin/env/git-authors ~/.git-authors
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

configure_zsh() {
  if [ ! -f $HOME/.zshrc ]; then
    sudo chsh -s /usr/bin/zsh $USER
    echo "" | SHELL=/usr/bin/zsh zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sed -i 's/robbyrussell/agnoster/' ~/.zshrc
    echo 'export EDITOR=nvim' >> ~/.zshrc
    echo '. $HOME/.venv/base/bin/activate' >> ~/.zshrc
    echo '. /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
    echo 'export PATH=/usr/local/cuda/bin:$PATH'  >> ~/.zshrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.zshrc
  fi
}

configure_git() {
  # https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases
  git config --global user.name "Brian Cunnie"
  git config --global user.email cunnie@majestic-labs.ai
  git config --global alias.co checkout
  git config --global alias.ci commit
  git config --global alias.st status
  git config --global url."git@github.com:".insteadOf "https://github.com/"
  git config --global color.branch auto
  git config --global color.diff auto
  git config --global color.status auto
  git config --global core.editor nvim
}

disable_firewalld() {
  sudo systemctl stop firewalld
  sudo systemctl disable firewalld
}

configure_python_venv() {
  VENV_DIR=$HOME/.venv/base
  if [ ! -d $VENV_DIR ]; then
    python3 -m venv $VENV_DIR
    source $VENV_DIR/bin/activate
    $VENV_DIR/base/bin/python3 -m pip install --upgrade pip
    pip install tensorflow
  fi
}

[ $(id -u) = 0 ] && ( echo "Do NOT run as root"; exit 1 )
# install_packages # should already been installed
mkdir -p ~/workspace
install_packages
configure_zsh          # needs to come before install steps that modify .zshrc
install_bin
install_git_duet
disable_firewalld
configure_git
configure_python_venv
