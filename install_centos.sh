#!/bin/bash -x
set -eu -o pipefail

# Source common functions
source "$(dirname "$0")/install_common.sh"

install_packages() {
  sudo dnf update -y
  sudo dnf install -y \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  sudo dnf groupinstall -y "Development Tools"
  sudo dnf install -y \
    binutils \
    btop \
    clang \
    cmake \
    dnf-plugins-core \
    fd-find \
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
    zsh-syntax-highlighting \

}

install_bin() {
  if [ ! -d $HOME/bin ]; then
    git clone git@github.com:cunnie/bin.git $HOME/bin
    echo 'PATH="$HOME/bin:$PATH:/usr/local/go/bin"' >> ~/.zshrc
  fi
}

configure_zsh() {
  if [ ! -f $HOME/.zshrc ]; then
    sudo chsh -s /usr/bin/zsh $USER
    echo "" | SHELL=/usr/bin/zsh zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sed -i 's/robbyrussell/agnoster/' ~/.zshrc
    echo 'export EDITOR=nvim' >> ~/.zshrc
    echo '. /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
    echo ' # CUDA, if installed'  >> ~/.zshrc
    echo 'export PATH=/usr/local/cuda/bin:$PATH'  >> ~/.zshrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.zshrc
    echo ' # autojump, because `fasd` is abandonware' >> ~/.zshrc
    echo '[ -s /etc/profile.d/autojump.sh ] && . /etc/profile.d/autojump.sh' >> ~/.zshrc
    echo 'alias z=j' >> ~/.zshrc
    echo " # Python, use a venv because you'll need to as soon as you install a module" >> ~/.zshrc
    echo '. $HOME/venv/bin/activate' >> ~/.zshrc
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

configure_python_venv() {
  VENV_DIR=$HOME/venv
  if [ ! -d $VENV_DIR ]; then
    python3 -m venv $VENV_DIR --prompt homedir
    source $VENV_DIR/bin/activate
    $VENV_DIR/bin/python3 -m pip install --upgrade pip
    pip install tensorflow
  fi
}

install_p10k() {
  if [ ! -e ~/.p10k.zsh ]; then
    cp ~/bin/env/p10k.zsh ~/.p10k.zsh
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/workspace/powerlevel10k
    cat >> $HOME/.zshrc <<EOF
source ~/workspace/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run "p10k configure" or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
  fi
}

[ $(id -u) = 0 ] && ( echo "Do NOT run as root"; exit 1 )
# install_packages # should already been installed
mkdir -p ~/workspace
install_packages
configure_zsh          # needs to come before install steps that modify .zshrc
install_bin
configure_git
configure_python_venv
redhat_install_google_cloud_cli
install_p10k
