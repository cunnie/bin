#!/bin/bash
set -eu -o pipefail

install_packages() {
  sudo dnf groupinstall -y "Development Tools"
  sudo dnf install -y \
    bin-utils \
    bind-utils \
    btrfs-progs \
    docker-compose \
    fd-find \
    git \
    golang \
    iproute \
    iputils \
    moby-engine \
    mysql-devel \
    neovim \
    net-tools \
    npm \
    openssl-devel \
    python \
    python3-neovim \
    redhat-rpm-config \
    ripgrep \
    ruby \
    ruby-devel \
    rubygems \
    strace \
    the_silver_searcher \
    tmux \
    util-linux-user \
    wget \
    zlib-devel \
    zsh \
    zsh-lovers \
    zsh-syntax-highlighting \

}

install_bosh_cli() {
  if [ ! -x /usr/local/bin/bosh ]; then
    curl -sL https://github.com/cloudfoundry/bosh-cli/releases/download/v6.4.1/bosh-cli-6.4.1-linux-amd64 -o /tmp/bosh
    sudo install /tmp/bosh /usr/local/bin
  fi
}

install_cf_cli() {
  if [ ! -x /usr/bin/cf ]; then
    sudo wget -O /etc/yum.repos.d/cloudfoundry-cli.repo https://packages.cloudfoundry.org/fedora/cloudfoundry-cli.repo
    sudo dnf install -y cf7-cli
  fi
}

install_chruby() {
  if [ ! -d /usr/local/share/chruby ] ; then
    wget -O ruby-install-0.7.0.tar.gz \
      https://github.com/postmodern/ruby-install/archive/v0.7.0.tar.gz
    tar -xzvf ruby-install-0.7.0.tar.gz
    cd ruby-install-0.7.0/
    sudo make install

    wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
    tar -xzvf chruby-0.3.9.tar.gz
    cd chruby-0.3.9/
    sudo make install
    cat >> ~/.zshrc <<EOF

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

install_fly_cli() {
  if [ ! -x /usr/local/bin/fly ]; then
    curl -s -o /tmp/fly 'https://ci.nono.io/api/v1/cli?arch=amd64&platform=linux'
    sudo install /tmp/fly /usr/local/bin
    sudo chmod a+w /usr/local/bin
  fi
}

install_om_cli() {
  if [ ! -x /usr/local/bin/om ]; then
    curl -s -L -o /tmp/om https://github.com/pivotal-cf/om/releases/download/6.3.0/om-linux-6.3.0
    sudo install /tmp/om /usr/local/bin
  fi
}

install_pivnet_cli() {
  if [ ! -x /usr/local/bin/pivnet ]; then
    curl -s -L -o /tmp/pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v2.0.1/pivnet-linux-amd64-2.0.1
    sudo install /tmp/pivnet /usr/local/bin
  fi
}

install_luan_nvim() {
  if [ ! -d $HOME/.config/nvim ]; then
    git clone https://github.com/luan/nvim $HOME/.config/nvim
  else
    echo "skipping Luan's config; it's already installed"
  fi
  # fix "missing dependencies (fd)!"
  if [ ! -f /usr/bin/fd ]; then
    sudo ln -s /usr/bin/fdfind /usr/bin/fd
  fi
}

install_terraform() {
  if [ ! -x /usr/local/bin/terraform ]; then
    curl -o tf.zip -L https://releases.hashicorp.com/terraform/0.14.7/terraform_0.14.7_linux_amd64.zip
    unzip tf.zip
    sudo install terraform /usr/local/bin/
  fi
}

install_aws_cli() {
  if [ ! -x /usr/local/bin/aws ]; then
    # From https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
  fi
}

install_zsh_autosuggestions() {
  if [ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
      sed -i 's/^plugins=(/&zsh-autosuggestions /' $HOME/.zshrc
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

configure_docker() {
  # https://fedoramagazine.org/docker-and-fedora-32/
  sudo systemctl enable docker
  sudo usermod -aG docker $USER
}

configure_zsh() {
  if [ ! -f $HOME/.zshrc ]; then
    sudo chsh -s /usr/bin/zsh $USER
    echo "" | SHELL=/usr/bin/zsh zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sed -i 's/robbyrussell/agnoster/' ~/.zshrc
    echo 'eval "$(fasd --init posix-alias zsh-hook)"' >> ~/.zshrc
    echo 'export EDITOR=nvim' >> ~/.zshrc
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

install_packages
configure_zsh          # needs to come before install steps that modify .zshrc
install_bosh_cli
install_cf_cli
install_chruby
install_fasd
install_fly_cli
install_om_cli
install_pivnet_cli
install_terraform
install_aws_cli
install_luan_nvim
install_zsh_autosuggestions
use_pacific_time
configure_direnv
configure_docker
configure_git
configure_tmux
