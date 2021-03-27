#!/bin/bash -x

# This script is meant to be an idempotent script (you can run it multiple
# times in a row).

# This script is meant to be run by the root user (via AWS's cloud-init /
# terraform's user_data) with no ssh key, no USER or HOME variable, and also be
# run by user cunnie, with ssh keys and environment variables set.

set -xeu -o pipefail

install_packages() {
  sudo dnf groupinstall -y "Development Tools"
  sudo dnf install -y \
    bind-utils \
    btrfs-progs \
    conntrack \
    containerd \
    containernetworking-plugins \
    cri-tools \
    direnv \
    fd-find \
    git \
    golang \
    iproute \
    ipset \
    iptables \
    iputils \
    kubernetes \
    kubernetes-kubeadm \
    mysql-devel \
    neovim \
    net-tools \
    nmap-ncat \
    npm \
    openssl-devel \
    python \
    python3-neovim \
    redhat-rpm-config \
    ripgrep \
    ruby \
    ruby-devel \
    rubygems \
    runc \
    socat \
    strace \
    the_silver_searcher \
    tmux \
    util-linux-user \
    wget \
    wireguard-tools \
    zlib-devel \
    zsh \
    zsh-lovers \
    zsh-syntax-highlighting \

  # don't use `dnf uninstall`; it removes the k8s dependencies
  sudo rpm -e moby-engine || true # don't need docker; don't need cluttered iptables
}

create_user_cunnie() {
  if ! id cunnie; then
    sudo adduser \
      --create-home \
      --shell=/usr/bin/zsh \
      --comment="Brian Cunnie" \
      --groups=adm,wheel,systemd-journal \
      cunnie
    mkdir ~cunnie/.ssh
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWiAzxc4uovfaphO0QVC2w00YmzrogUpjAzvuqaQ9tD cunnie@nono.io " > ~cunnie/.ssh/authorized_keys
    ssh-keyscan github.com > ~cunnie/.ssh/known_hosts
    sudo chown -R cunnie:cunnie ~cunnie
    sudo -u cunnie chmod -R go-rwx ~cunnie/.ssh
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
    cat >> $HOME/.zshrc <<EOF

source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh
EOF
  fi
}

install_fasd() {
  if [ ! -x /usr/local/bin/fasd ]; then
    cd $HOME/workspace
    git clone https://github.com/clvv/fasd.git
    cd fasd
    sudo make install
    cat >> $HOME/.zshrc <<EOF

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
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip"
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
  if ! grep -q "direnv hook zsh" $HOME/.zshrc; then
    echo 'eval "$(direnv hook zsh)"' >> $HOME/.zshrc
    eval "$(direnv hook bash)"
  fi
  for envrc in $(find "$HOME/workspace" -maxdepth 2 -name '.envrc' -print); do
    pushd $(dirname $envrc)
      direnv allow
    popd
  done
}

configure_zsh() {
  if [ ! -d $HOME/.oh-my-zsh ]; then
    sudo chsh -s /usr/bin/zsh $USER
    echo "" | SHELL=/usr/bin/zsh zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sed -i 's/robbyrussell/agnoster/' $HOME/.zshrc
    echo 'eval "$(fasd --init posix-alias zsh-hook)"' >> $HOME/.zshrc
    echo 'export EDITOR=nvim' >> $HOME/.zshrc
  fi
}

use_pacific_time() {
  sudo timedatectl set-timezone America/Los_Angeles
}

disable_selinux() {
  if grep -q SELINUX=enforcing /etc/selinux/config; then
    printf "disabling SELINUX and firewall"
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
  fi
}

configure_git() {
  # https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases
  git config --global user.name "Brian Cunnie"
  git config --global user.email brian.cunnie@gmail.com
  git config --global alias.co checkout
  git config --global alias.ci commit
  git config --global alias.st status
  git config --global color.branch auto
  git config --global color.diff auto
  git config --global color.status auto
  git config --global core.editor nvim

  mkdir -p $HOME/workspace # where we typically clone our repos
}

configure_sudo() {
  sudo sed -i 's/# %wheel/%wheel/' /etc/sudoers
}

configure_tmux() {
  # https://github.com/luan/tmuxfiles, to clear, `rm -rf ~/.tmux.conf ~/.tmux`
  if [ ! -f $HOME/.tmux.conf ]; then
    echo "WARNING: If this scripts fails with \"unknown variable: TMUX_PLUGIN_MANAGER_PATH\""
    echo "If you don't have an ugly magenta bottom of your tmux screen, if nvim is unusable, then"
    echo "you may need to run this command to completely install tmux configuration:"
    echo "zsh -c \"\$(curl -fsSL https://raw.githubusercontent.com/luan/tmuxfiles/master/install)\""
    su - cunnie zsh -c "$(curl -fsSL https://raw.githubusercontent.com/luan/tmuxfiles/master/install)"
  fi
}

disable_swap() {
  if [ ! "$(sudo swapon --show)" = "" ]; then
    sudo swapoff -a;
    sudo sed --in-place '/none *swap /d' /etc/fstab;
    sudo systemctl daemon-reload
  fi
}

make_k8s_dirs() {
  sudo mkdir -p \
    /etc/cni/net.d \
    /var/lib/kubernetes \
    /var/lib/kube-proxy \

}

configure_cni_networking() {
  if [ ! -f /etc/cni/net.d/10-bridge.conf ]; then
    HOSTNAME=$(hostname)
    POD_CIDR_THIRD_OCTET=${HOSTNAME#worker-}
    if [[ $POD_CIDR_THIRD_OCTET =~ ^[0-9]+$ ]]; then
      POD_CIDR="10.200.$POD_CIDR_THIRD_OCTET.0/24"
    else
      echo "hostname must be set to something that matches 'worker-[0-9]+'" 1>&2
      exit 1
    fi
    sudo tee /etc/cni/net.d/10-bridge.conf <<EOF
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
  fi
  if [ ! -f /etc/cni/net.d/99-loopback.conf ]; then
    sudo tee /etc/cni/net.d/99-loopback.conf <<EOF
{
    "cniVersion": "0.3.1",
    "name": "lo",
    "type": "loopback"
}
EOF
  fi
}

configure_containerd() {
  if [ ! -f /etc/systemd/system/containerd.service ]; then
    sudo tee /etc/containerd/config.toml <<EOF
[plugins]
[plugins.cri.containerd]
  snapshotter = "overlayfs"
  [plugins.cri.containerd.default_runtime]
    runtime_type = "io.containerd.runtime.v1.linux"
    runtime_engine = "/usr/bin/runc"
    runtime_root = ""
[plugins.cri.cni]
  bin_dir = "/usr/libexec/cni"
EOF
    sudo tee /etc/systemd/system/containerd.service <<EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/usr/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
  fi
}

ARCH=$(uname -i)
install_packages
create_user_cunnie
export HOME=${HOME:-~cunnie}
export USER=${USER:-cunnie}
mkdir -p $HOME/workspace # sometimes run as root via terraform user_data, no HOME
configure_zsh          # needs to come before install steps that modify .zshrc
install_chruby
install_fasd
install_fly_cli
install_terraform
install_aws_cli
install_luan_nvim
install_zsh_autosuggestions
use_pacific_time
disable_selinux
configure_direnv
configure_git
configure_sudo
configure_tmux
disable_swap
make_k8s_dirs
configure_cni_networking
configure_containerd

sudo chown -R cunnie:cunnie ~cunnie
git config --global url."git@github.com:".insteadOf "https://github.com/"
