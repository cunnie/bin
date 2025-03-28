#!/bin/bash -x

# This script is meant to be an idempotent script (you can run it multiple
# times in a row).

# This script is meant to be run by the root user
# terraform's custom_data) with no ssh key, no USER or HOME variable, and also
# be run by user cunnie, with ssh keys and environment variables set.

# to troubleshoot: ssh ubuntu@ns-vsphere

# Output is in /var/log/cloud-init-output.log

set -xeu -o pipefail

install_packages() {
  sudo apt-get update
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get -y upgrade
  sudo apt-get remove -y chrony || true
  sudo apt-get install -y \
    bat \
    build-essential \
    direnv \
    fasd \
    fd-find \
    git \
    git-lfs \
    golang \
    jq \
    neovim \
    nginx \
    ntpsec \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ripgrep \
    ruby \
    socat \
    tcpdump \
    tree \
    unzip \
    zsh \
    zsh-syntax-highlighting \

}

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
    echo '. $HOME/.venv/base/bin/activate' >> ~/.zshrc
  fi
}

use_pacific_time() {
  sudo timedatectl set-timezone America/Los_Angeles
}

disable_selinux() {
  # does not take effect until reboot, and we can't reboot halfway through the script
  # because we can't easily pick up where we left off
  if grep -q SELINUX=enforcing /etc/selinux/config; then
    printf "disabling SELINUX and firewall"
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
    # The following really, truly disables selinux
    sudo grubby --update-kernel ALL --args selinux=0
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
    sudo systemctl restart syslog
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
  git config --global url."git@github.com:".insteadOf "https://github.com/"

  mkdir -p $HOME/workspace # where we typically clone our repos
}

configure_sudo() {
  sudo sed -i 's/# %wheel/%wheel/' /etc/sudoers
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
    sudo systemctl enable ntpsec
    sudo systemctl start ntpsec
  fi
}

install_sslip_io_dns() {
  if [ ! -x /usr/bin/sslip.io-dns-server ]; then
    GOLANG_ARCH=$ARCH
    GOLANG_ARCH=${GOLANG_ARCH/aarch64/arm64}
    GOLANG_ARCH=${GOLANG_ARCH/x86_64/amd64}
    curl -L https://github.com/cunnie/sslip.io/releases/download/2.7.0/sslip.io-dns-server-linux-$GOLANG_ARCH \
      -o sslip.io-dns-server
    sudo install sslip.io-dns-server /usr/bin
    sudo curl -L https://raw.githubusercontent.com/cunnie/deployments/master/terraform/aws/sslip.io-vm/sslip.io.service \
      -o /etc/systemd/system/sslip.io-dns.service
    sudo systemctl daemon-reload
    sudo systemctl enable sslip.io-dns
    sudo systemctl start sslip.io-dns
  fi
}

delete_adminuser() {
  if grep -q ^ubuntu: /etc/passwd; then
    sudo deluser --remove-home ubuntu
  fi
}

install_docker() {
  # https://docs.docker.com/engine/install/ubuntu/
  if [ ! -x /usr/bin/docker ]; then
    sudo apt-get install \
      ca-certificates \
      curl \
      gnupg \
      lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo adduser cunnie docker
  fi
}

configure_python_venv() {
  VENV_DIR=$HOME/.venv/base
  if [ ! -d $VENV_DIR ]; then
    python3 -m venv $VENV_DIR
    source $VENV_DIR/bin/activate
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

id # Who am I? for debugging purposes
START_TIME=$(date +%s)
ARCH=$(uname -i)
export HOSTNAME=$(hostname)
install_packages
configure_sudo
create_user_cunnie
use_pacific_time
disable_selinux
rsyslog_ignores_sslip

if id -u cunnie && [ $(id -u) == $(id -u cunnie) ]; then
  configure_git
  mkdir -p $HOME/workspace # sometimes run as root via terraform user_data, no HOME
  configure_zsh          # needs to come before install steps that modify .zshrc
  install_chruby
  install_terraform
  install_aws_cli
  install_zsh_autosuggestions
  install_docker
  configure_direnv
  install_p10k
  configure_ntp
  configure_python_venv
  install_sslip_io_dns
  delete_adminuser # AMI includes an ubuntu user; delete it
fi
echo "It took $(( $(date +%s) - START_TIME )) seconds to run"
