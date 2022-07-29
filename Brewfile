# TKS and TKGI are installed from https://network.pivotal.io/products/pivotal-container-service/

tap "adoptopenjdk/openjdk"
tap "cloudfoundry/tap"
tap "git-duet/tap"
tap "golangci/tap"
tap "homebrew/bundle"
tap "homebrew/cask"
tap "homebrew/cask-versions"
tap "homebrew/core"
tap "homebrew/services"
tap "vmware-tanzu/carvel"
tap "pivotal-cf/kiln", "https://github.com/pivotal-cf/kiln"
tap "pivotal-cf/om", "https://github.com/pivotal-cf/om"
tap "pivotal/tap"

brew "automake"
brew "awscli"
brew "azure-cli" # for terraforming ns-azure
brew "bat" # luan nvim dependency
brew "bbl" # The x86_64 architecture is required for this software.
brew "bison"
brew "cdrtools" # ln -s $(brew --prefix)/bin/{mkisofs,genisoimage} # fixes 127 -sh: genisoimage: command not found
brew "cfssl"
brew "chruby"
brew "cmake"
brew "dependency-check"
brew "direnv"
brew "docker" # CLI only
brew "etcd" # for sslip.io backend database
brew "fasd"
brew "fd"
brew "gdbm"
brew "git"
brew "git-lfs"
brew "gnu-sed"
brew "go"
brew "govc"
brew "gopls" # for Luan's nvim
brew "helm"
brew "htop"
brew "hub"
brew "hugo"
brew "jq"
brew "vmware-tanzu/carvel/kapp"
brew "vmware-tanzu/carvel/kbld"
brew "vmware-tanzu/carvel/vendir"
brew "vmware-tanzu/carvel/ytt"
brew "kiln"
brew "kubernetes-cli"
brew "lastpass-cli"
brew "libdvdcss"
brew "libffi"
brew "libpq"
brew "libyaml"
brew "mysql"
brew "neovim"
brew "node" # Operations Manager
brew "nodenv" # Operations Manager
brew "openssl@1.1"
brew "openssl@3"
brew "openvpn" # to reach Nimbus VMs
brew "postgresql@11" # needed for ruby-install 3.1.2 "configure: error: something wrong with LDFLAGS="-L/opt/homebrew/opt/postgresql@11/lib""
brew "postgresql@13", restart_service: true # Operations Manager
brew "python@3.8"
brew "python@3.9"
brew "qrencode"
brew "readline"
brew "ripgrep"
brew "ruby-install"
brew "sshuttle"
brew "swagger-codegen" # vSphere CPI
brew "terraform"
brew "the_silver_searcher"
brew "tidy-html5"
brew "tmux"
brew "tree"
brew "uaa-cli" # The x86_64 architecture is required for this software.
brew "vault"
brew "vim"
brew "vips"
brew "watch"
brew "wget"
brew "wireguard-tools" # need `wg` to generate public & private keys
brew "yarn" # Operations Manager
brew "youtube-dl"
# brew "yq" # Ops Mgr depends on v3; don't install v4
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-git-prompt"
brew "zsh-lovers"
brew "zsh-syntax-highlighting"

brew "cloudfoundry/tap/bosh-cli"
brew "cloudfoundry/tap/cf-cli@7"
brew "cloudfoundry/tap/credhub-cli" # The x86_64 architecture is required for this software.
brew "git-duet/tap/git-duet"
brew "golangci/tap/golangci-lint"
brew "pivotal-cf/kiln/kiln"
brew "pivotal-cf/om/om"
brew "vmware-tanzu/carvel/ytt" # need ytt for pivotal/bosh-ecosystem-concourse/pipelines/configure.sh

cask "adoptopenjdk11"
cask "battle-net"
cask "discord"
cask "firefox"
cask "flycut"
cask "gimp"
cask "google-chrome"
cask "google-cloud-sdk"
cask "google-drive"
cask "gpg-suite"
cask "handbrake"
cask "inkscape"
cask "istat-menus"
cask "iterm2"
cask "jetbrains-toolbox"
cask "makemkv"
cask "messenger" # Facebook messenger to sell things on FB Marketplace
cask "microsoft-azure-storage-explorer"
cask "powershell" # This package requires Rosetta 2 to be installed.
cask "rancher"
cask "rectangle"
cask "sequel-pro-nightly"
cask "signal"
cask "skype"
cask "slack"
cask "spotify"
cask "steam"
cask "tunnelblick"
# cask "vagrant" # Docker has largely supplanted vagrant # This package requires Rosetta 2 to be installed.
# cask "virtualbox" # Error: Cask virtualbox depends on hardware architecture being one of [{:type=>:intel, :bits=>64}], but you are running {:type=>:arm, :bits=>64}.
cask "visual-studio-code"
cask "vlc"
cask "vmware-fusion-tech-preview" # Because it's cool
cask "whatsapp"
cask "wireshark"
cask "xquartz"
cask "zoom"
