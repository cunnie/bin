#!/bin/bash -x

# This script is meant to be an idempotent script (you can run it multiple
# times in a row).

# This script is meant to be run by the root user (via GCP's cloud-init /
# terraform's custom_data) with no ssh key, no USER or HOME variable, and also
# be run by user cunnie, with ssh keys and environment variables set.

# gcloud compute ssh --zone "us-central1-a" "ns-gce" --project "blabbertabber"

# Output is in /var/log/cloud-init-output.log

set -xeu -o pipefail

# Source common functions
source "$(dirname "$0")/install_common.sh"

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
    curl -L https://github.com/cunnie/sslip.io/releases/download/4.1.0/sslip.io-dns-server-linux-$GOLANG_ARCH \
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

delete_weird_google_users() {
  for WEIRDO in bosh vcap evanbrown; do
    if grep -q ^$WEIRDO: /etc/passwd; then
      sudo deluser --remove-home $WEIRDO
    fi
  done
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

id # Who am I? for debugging purposes
START_TIME=$(date +%s)
ARCH=$(uname -m) # `uname -i` returns "unknown" on GCP
export HOSTNAME=$(hostname)
ubuntu_install_packages
configure_sudo
configure_user_cunnie
use_pacific_time
rsyslog_ignores_sslip

if id -u cunnie && [ $(id -u) == $(id -u cunnie) ]; then
  configure_git
  mkdir -p $HOME/workspace # sometimes run as root via terraform user_data, no HOME
  configure_zsh          # needs to come before install steps that modify .zshrc
  install_chruby
  install_zsh_autosuggestions
  configure_direnv
  install_p10k
  configure_ntp
  install_sslip_io_dns
  install_sslip_io_web # installs HTTP only
  # don't bother with TLS, "Invalid identifiers requested :: Cannot issue for \"2600-1900-4000-4d12--.sslip.io\": Domain name contains an invalid character"
  # install_tls # gets certs & updates nginx to include HTTPS
  delete_adminuser # AMI includes an ubuntu user; delete it
  delete_weird_google_users
fi
echo "It took $(( $(date +%s) - START_TIME )) seconds to run"
