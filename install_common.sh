#!/bin/bash -x

# Common functions used by installation scripts
# This file should be sourced by the installation scripts

set -xeu -o pipefail

ubuntu_install_packages() {
  sudo apt-get update
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get -y upgrade
  sudo apt-get remove -y chrony || true
  sudo apt-get install -y \
    autoconf \
    automake \
    bat \
    build-essential \
    clang \
    cmake \
    device-tree-compiler \
    direnv \
    fasd \
    fd-find \
    git \
    git-lfs \
    golang \
    jq \
    libftdi1 \
    libglib2.0-0 \
    libgmp10 \
    libhidapi-hidraw0 \
    libpixman-1-0 \
    libtool \
    neovim \
    nginx \
    ninja-build \
    ntpsec \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-venv \
    python3-wheel \
    ripgrep \
    ruby \
    socat \
    swig \
    tcpdump \
    tree \
    unzip \
    wget \
    zsh \
    zsh-syntax-highlighting
}

ubuntu_install_nvidia_packages() {
  # install NVIDIA drivers if NVIDIA card
  sudo ubuntu-drivers autoinstall

  if [ "$(uname -m)" = x86_64 ]; then
    sudo apt-get install -y \
      nvidia-cuda-toolkit
  fi
}

ubuntu_install_gcloud() {
  if ! gcloud config get project ; then
    sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \

    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo apt-get update && sudo apt-get install -y google-cloud-cli
  fi
}

ubuntu_install_vnc() {
  if [ ! -d /etc/tigervnc ]; then
    sudo apt-get install -y \
      tigervnc-standalone-server \
      ubuntu-desktop \

    printf "\n:1=$USER\n" | \
      sudo tee -a /etc/tigervnc/vncserver.users
    printf '\n$localhost = "yes";\n$geometry = "2000x1200";\n' | \
      sudo tee -a /etc/tigervnc/vncserver-config-defaults
    sudo cp -i /usr/lib/systemd/system/tigervncserver@.service \
      /etc/systemd/system/vncserver@:1.service
    sudo -u ${USER} mkdir -p ~${USER}/.vnc
    sudo systemctl daemon-reload
    sudo systemctl enable vncserver@:1
    sudo systemctl restart vncserver@:1
    printf "---------"
    printf "Remember to run 'tigervncpasswd'"
    printf "Remember to run 'sudo passwd $USER'"
    printf "---------"
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
    curl -L https://github.com/cunnie/sslip.io/releases/download/3.2.7/sslip.io-dns-server-linux-$GOLANG_ARCH \
      -o sslip.io-dns-server
    sudo install sslip.io-dns-server /usr/bin
    sudo curl -L https://raw.githubusercontent.com/cunnie/deployments/main/terraform/aws/sslip.io-vm/sslip.io.service \
      -o /etc/systemd/system/sslip.io-dns.service
    sudo systemctl daemon-reload
    sudo systemctl enable sslip.io-dns
    sudo systemctl start sslip.io-dns
  fi
}

install_sslip_io_web() {
  # Fix "conflicting server name "_" on 0.0.0.0:80, ignored"
  if [ -L /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
    sudo systemctl enable nginx
    sudo systemctl start nginx
    if [ ! -d ~/workspace/sslip.io ]; then
      git clone https://github.com/cunnie/sslip.io.git ~/workspace/sslip.io
    fi
  fi
  HTML_DIR=/var/nginx/sslip.io
  if [ ! -d $HTML_DIR ]; then
    sudo mkdir -p $HTML_DIR
    sudo rsync -avH ~/workspace/sslip.io/k8s/document_root_sslip.io/ $HTML_DIR/
    sudo chown -R $USER $HTML_DIR
    sudo chmod -R g+w $HTML_DIR # so I can write acme certificate information
    sudo curl -L https://raw.githubusercontent.com/cunnie/deployments/main/terraform/azure/sslip.io-vm/sslip.io.nginx.conf \
      -o /etc/nginx/conf.d/sslip.io.conf
    sudo systemctl restart nginx # enable sslip.io HTTP
    sudo chmod g+rx /var/log/nginx # so I can look at the logs without running sudo
    sudo chown -R www-data:www-data $HTML_DIR
  fi
}

delete_adminuser() {
  if grep -q ^ubuntu: /etc/passwd; then
    sudo deluser --remove-home ubuntu
  fi
}

redhat_install_google_cloud_cli() {
  if [ ! -f /etc/yum.repos.d/google-cloud-sdk.repo ]; then
    sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
    sudo dnf install -y google-cloud-cli
  fi
}

install_tls() {
  TLS_DIR=/etc/pki/nginx
  if [ ! -d $TLS_DIR ]; then
    HTML_DIR=/var/nginx/sslip.io
    sudo chown -R $USER $HTML_DIR
    PUBLIC_IPV4=$(dig @ns.sslip.io ip.sslip.io TXT +short -4 | tr -d \")
    PUBLIC_IPV6=$(dig @ns.sslip.io ip.sslip.io TXT +short -6 | tr -d \")
    PUBLIC_IPV4_DASHES=${PUBLIC_IPV4//./-}
    PUBLIC_IPV6_DASHES=${PUBLIC_IPV6//:/-}
    curl https://get.acme.sh | sh -s email=brian.cunnie@gmail.com
    ~/.acme.sh/acme.sh \
      --issue \
      -d $PUBLIC_IPV4.sslip.io \
      -d $PUBLIC_IPV4_DASHES.sslip.io \
      -d $PUBLIC_IPV6_DASHES.sslip.io \
      --server    https://acme-v02.api.letsencrypt.org/directory \
      --keylength ec-256  \
      --log \
      -w /var/nginx/sslip.io || true # it'll fail & exit if the cert's already issued, but we don't want to exit
    sudo mkdir -p $TLS_DIR
    sudo chown -R $USER $TLS_DIR
    mkdir -p $TLS_DIR/private/
    touch $TLS_DIR/server.crt $TLS_DIR/private/server.key
    chmod -R g+w $TLS_DIR
    chmod -R o-rwx $TLS_DIR/private
    sudo chown -R $USER $HTML_DIR
    ~/.acme.sh/acme.sh \
      --install-cert \
      -d $PUBLIC_IPV4.sslip.io \
      -d $PUBLIC_IPV4_DASHES.sslip.io \
      -d $PUBLIC_IPV6_DASHES.sslip.io \
      --ecc \
      --key-file       $TLS_DIR/private/server.key  \
      --fullchain-file $TLS_DIR/server.crt \
      --server         https://acme-v02.api.letsencrypt.org/directory \
      --reloadcmd      "sudo systemctl restart nginx" \
      --log
    sudo chown -R www-data:www-data $TLS_DIR $HTML_DIR
    # Now that we have a cert we can safely load nginx's HTTPS configuration
    sudo curl -L https://raw.githubusercontent.com/cunnie/deployments/main/terraform/azure/sslip.io-vm/sslip.io-https.nginx.conf \
      -o /etc/nginx/conf.d/sslip.io-https.conf
    sudo systemctl restart nginx # enable sslip.io HTTPS
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