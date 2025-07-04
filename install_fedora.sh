#!/bin/bash -x
set -eu -o pipefail

install_packages() {
  sudo dnf group install -y development-tools
  sudo dnf install -y \
    autojump-zsh \
    bind-chroot \
    bind-utils \
    binutils \
    btop \
    btrfs-progs \
    cmake \
    cronie \
    damo \
    direnv \
    dnf-plugins-core \
    etcd \
    fd-find \
    gcc-g++ \
    git \
    git-lfs \
    gnuplot \
    golang-x-tools-gopls \
    hdf5-devel \
    htop \
    iperf3 \
    iproute \
    iputils \
    jq \
    libcurl-devel \
    libxml2-devel \
    msr-tools \
    mysql-devel \
    neovim \
    net-tools \
    nmap-ncat \
    npm \
    openssl-devel \
    perf \
    postgresql-devel \
    python \
    python-devel \
    python3-numpy \
    python3-pip \
    redhat-rpm-config \
    ripgrep \
    ruby \
    ruby-devel \
    rubygems \
    socat \
    strace \
    tcpdump \
    the_silver_searcher \
    tmux \
    util-linux-user \
    wget \
    zlib-devel \
    zsh \
    zsh-lovers \
    zsh-syntax-highlighting \

}

install_azure_cli() {
  if [ ! -x /usr/bin/az ]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
    sudo dnf install -y azure-cli
  fi
}

install_bosh_cli() {
  if [ ! -x /usr/local/bin/bosh ]; then
    curl -sL https://github.com/cloudfoundry/bosh-cli/releases/download/v7.8.2/bosh-cli-7.8.2-linux-amd64 -o /tmp/bosh
    sudo install /tmp/bosh /usr/local/bin
  fi
}

install_bitwarden() {
  if [ ! -x /usr/local/bin/bw ]; then
    pushd /tmp/
    curl -sL "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o bw.zip
    unzip -o bw.zip
    sudo install bw /usr/local/bin
    popd
  fi
}

install_chruby() {
  if [ ! -d /usr/local/share/chruby ] ; then
    wget -O ruby-install-0.8.3.tar.gz https://github.com/postmodern/ruby-install/archive/v0.8.3.tar.gz
    tar -xzvf ruby-install-0.8.3.tar.gz
    cd ruby-install-0.8.3/
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

install_go() {
  if [ ! -d /usr/local/go ]; then
    curl -L https://go.dev/dl/go1.20.1.linux-amd64.tar.gz -o /tmp/go.tgz
    sudo tar -C /usr/local -xzvf /tmp/go.tgz
  fi
}

install_bin() {
  if [ ! -d $HOME/bin ]; then
    git clone git@github.com:cunnie/bin.git $HOME/bin
    echo 'PATH="$HOME/bin:$PATH:/usr/local/go/bin"' >> ~/.zshrc
    ln -s ~/bin/env/git-authors ~/.git-authors
  fi
}


install_fly_cli() {
  if [ ! -x $HOME/bin/fly ]; then
    curl -s -o $HOME/bin/fly 'https://ci.majestic-labs.ai/api/v1/cli?arch=amd64&platform=linux'
    sudo chmod +x $HOME/bin/fly
  fi
}

install_terraform() {
  if [ ! -x /usr/local/bin/terraform ]; then
    curl -o tf.zip -L https://releases.hashicorp.com/terraform/1.6.3/terraform_1.6.3_linux_amd64.zip
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

install_gcloud() {
  if [ "$(uname -m)" = x86_64 ]; then
    YUM_REPO_PATH=/etc/yum.repos.d/google-cloud-sdk.repo
    if [ ! -f $YUM_REPO_PATH ]; then
      sudo tee -a $YUM_REPO_PATH << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
      sudo dnf install -y google-cloud-sdk
    fi
  fi
}

install_yq() {
  if [ ! -x /usr/local/bin/yq ]; then
    curl -o yq -L https://github.com/mikefarah/yq/releases/download/v4.14.1/yq_linux_amd64
    chmod +x yq
    sudo install yq /usr/local/bin/
    rm yq
  fi
}

install_vault() {
  if [ ! -x /usr/bin/vault ]; then
    sudo dnf-3 config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf -y install vault
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

install_docker() {
  if [ ! -x /usr/bin/docker ]; then
    # https://docs.docker.com/engine/install/fedora/
    sudo sudo dnf -y install dnf-plugins-core
    sudo dnf-3 config-manager \
      --add-repo \
      https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # https://fedoramagazine.org/docker-and-fedora-32/
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    # fixes "ERROR: multiple platforms feature is currently not supported for docker driver."
    docker buildx create --use
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

disable_firewalld() {
  # so that BIND can work
  sudo systemctl stop firewalld
  sudo systemctl disable firewalld
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
  VENV_DIR=$HOME/venv
  if [ ! -d $VENV_DIR ]; then
    python3 -m venv $VENV_DIR
    source $VENV_DIR/bin/activate
    pip install --upgrade pip
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
install_packages
mkdir -p ~/workspace
configure_zsh          # needs to come before install steps that modify .zshrc
install_aws_cli
install_azure_cli
install_bin
install_bitwarden
install_bosh_cli
install_chruby
install_docker
# install_fly_cli
install_gcloud
install_git_duet
install_go
install_terraform
install_vault
install_yq
install_zsh_autosuggestions
use_pacific_time
disable_firewalld
configure_bind
configure_direnv
configure_git
configure_tmux
configure_passwordless_sudo
configure_python_venv
install_p10k
[ ! -f /usr/lib64/libsqlite3.so ] && [ -f /usr/lib64/libsqlite3.so.0 ] && sudo ln -s /usr/lib64/libsqlite3.so.0 /usr/lib64/libsqlite3.so
