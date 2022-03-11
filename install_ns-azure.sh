#!/bin/bash -x

# This script is meant to be an idempotent script (you can run it multiple
# times in a row).

# This script is meant to be run by the root user (via AWS's cloud-init /
# terraform's user_data) with no ssh key, no USER or HOME variable, and also be
# run by user cunnie, with ssh keys and environment variables set.

set -xeu -o pipefail

install_packages() {
  sudo apt-get update
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get -y upgrade
  sudo apt-get remove -y chrony || true
  sudo apt-get install -y \
    build-essential \
    direnv \
    fasd \
    fd-find \
    golang \
    lastpass-cli \
    neovim \
    nginx \
    ntpsec \
    silversearcher-ag \
    socat \
    tcpdump \
    tree \
    unzip \
    zsh \
    zsh-syntax-highlighting \

  if ! grep grml /etc/apt/sources.list; then
    echo "deb     http://deb.grml.org/ grml-stable  main" | sudo tee -a /etc/apt/sources.list
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 21E0CA38EA2EA4AB
    sudo apt-get update
    sudo apt-get install -y \
	    zsh-lovers
  fi
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
    sudo adduser $USER www-data
    sudo mkdir ~cunnie/.ssh
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWiAzxc4uovfaphO0QVC2w00YmzrogUpjAzvuqaQ9tD cunnie@nono.io " | sudo tee -a ~cunnie/.ssh/authorized_keys
    ssh-keyscan github.com | sudo tee -a ~cunnie/.ssh/known_hosts
    sudo chown -R cunnie:cunnie ~cunnie
    sudo -u cunnie chmod -R go-rwx ~cunnie/.ssh
    echo "cunnie ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-cunnie
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
  if [ ! -L /usr/bin/fd ]; then
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
  # does not take effect until reboot, and we can't reboot halfway through the script
  # because we can't easily pick up where we left off
  if grep -q SELINUX=enforcing /etc/selinux/config; then
    printf "disabling SELINUX and firewall"
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
    # The following really, truly disables selinux
    sudo grubby --update-kernel ALL --args selinux=0
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
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/luan/tmuxfiles/master/install)"
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
    sudo systemctl enable ntpsec
    sudo systemctl start ntpsec
  fi
}

install_sslip_io_dns() {
  if [ ! -x /usr/bin/sslip.io-dns-server ]; then
    GOLANG_ARCH=${ARCH/aarch64/arm64/}
    curl -L https://github.com/cunnie/sslip.io/releases/download/2.1.2/sslip.io-dns-server-linux-$GOLANG_ARCH \
      -o sslip.io-dns-server
    sudo install sslip.io-dns-server /usr/bin
    sudo curl -L https://raw.githubusercontent.com/cunnie/deployments/master/terraform/aws/sslip.io-vm/sslip.io.service \
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
    sudo rsync -avH ~/workspace/sslip.io/k8s/document_root/ $HTML_DIR/
    sudo chown -R $USER $HTML_DIR
    sudo chmod -R g+w $HTML_DIR # so I can write acme certificate information
    sudo curl -L https://raw.githubusercontent.com/cunnie/deployments/master/terraform/aws/sslip.io-vm/sslip.io.nginx.conf \
      -o /etc/nginx/conf.d/sslip.io.conf
    sudo systemctl restart nginx # enable sslip.io HTTP
    sudo chmod g+rx /var/log/nginx # so I can look at the logs without running sudo
    sudo chown -R www-data:www-data $HTML_DIR
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
    ~/.acme.sh/acme.sh --issue \
      -d $PUBLIC_IPV4.sslip.io \
      -d $PUBLIC_IPV4_DASHES.sslip.io \
      -d $PUBLIC_IPV6_DASHES.sslip.io \
      --log \
      -w /var/nginx/sslip.io || true # it'll fail & exit if the cert's already issued, but we don't want to exit
    sudo mkdir -p $TLS_DIR
    sudo chown -R $USER $TLS_DIR
    mkdir -p $TLS_DIR/private/
    touch $TLS_DIR/server.crt $TLS_DIR/private/server.key
    chmod -R g+w $TLS_DIR
    chmod -R o-rwx $TLS_DIR/private
    sudo chown -R $USER $HTML_DIR
    ~/.acme.sh/acme.sh --install-cert \
      -d $PUBLIC_IPV4.sslip.io \
      -d $PUBLIC_IPV4_DASHES.sslip.io \
      -d $PUBLIC_IPV6_DASHES.sslip.io \
      --key-file       $TLS_DIR/private/server.key  \
      --fullchain-file $TLS_DIR/server.crt \
      --reloadcmd     "sudo systemctl restart nginx" \
      --log
    sudo chown -R www-data:www-data $TLS_DIR $HTML_DIR
    # Now that we have a cert we can safely load nginx's HTTPS configuration
    sudo curl -L https://raw.githubusercontent.com/cunnie/deployments/master/terraform/aws/sslip.io-vm/sslip.io-https.nginx.conf \
      -o /etc/nginx/conf.d/sslip.io-https.conf
    sudo systemctl restart nginx # enable sslip.io HTTPS
  fi
}

START_TIME=$(date +%s)
ARCH=$(uname -i)
export HOME=${HOME:-~cunnie}
export USER=${USER:-cunnie}
export HOSTNAME=$(hostname)
install_packages
create_user_cunnie
mkdir -p $HOME/workspace # sometimes run as root via terraform user_data, no HOME
configure_zsh          # needs to come before install steps that modify .zshrc
install_chruby
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
configure_ntp
install_sslip_io_dns
install_sslip_io_web # installs HTTP only
install_tls # gets certs & updates nginx to include HTTPS

sudo chown -R cunnie:cunnie ~cunnie
git config --global url."git@github.com:".insteadOf "https://github.com/"
echo "It took $(( $(date +%s) - START_TIME )) seconds to run"