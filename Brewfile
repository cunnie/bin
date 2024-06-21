# TKS and TKGI are installed from https://network.pivotal.io/products/pivotal-container-service/

tap "cloudfoundry/tap"
tap "git-duet/tap"
tap "golangci/tap"
tap "homebrew/bundle"
tap "homebrew/services"
# Even though we don't use "k14s/tap", including it gets rid of this message when installing ytt:
#   "Please use the fully-qualified name (e.g. k14s/tap/ytt) to refer to the formula."
# tap "k14s/tap"
tap "pivotal-cf/om", "https://github.com/pivotal-cf/om"
brew "autojump" # replaces "fasd", which has an archived upstream repo
brew "automake"
brew "awscli"
brew "azure-cli" # for terraforming ns-azure
brew "bat" # luan nvim dependency
brew "bison"
brew "bosh-cli" # commenting-out to avoid "Error: key not found: "cloudfoundry/tap/bosh-cli"
brew "cdrtools" # ln -s $(brew --prefix)/bin/{mkisofs,genisoimage} # fixes 127 -sh: genisoimage: command not found
brew "cfssl"
brew "chruby"
brew "cmake"
brew "dependency-check"
brew "direnv"
brew "docker" # CLI only
brew "docker-credential-helper" # fixes `docker buildx` → "exec: "docker-credential-osxkeychain": executable file not found in $PATH"
brew "etcd" # for sslip.io backend database
brew "fd"
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
brew "iperf3"
brew "jq"
brew "kubernetes-cli"
brew "lastpass-cli"
brew "libdvdcss"
brew "libffi"
brew "libpq"
brew "libyaml"
brew "mysql"
brew "neovim"
brew "openssl@1.1"
brew "openssl@3"
brew "openstackclient" # Lakin says we need it to manage our cluster
brew "packer" # needed for ops-manager/vm, to create OM VMs
brew "postgresql@13", restart_service: true # Operations Manager
brew "python"
brew "python@3.8" # needed for Google Cloud SDK https://cloud.google.com/sdk/gcloud/reference/topic/startup
brew "qemu" # so I can convert MS Windows VHDX to a VMDK to run VMware Fusion
brew "qrencode"
brew "readline"
brew "ripgrep"
brew "ruby-install"
brew "sshuttle"
brew "terraform"
brew "the_silver_searcher"
brew "tidy-html5"
brew "tmux"
brew "tree"
brew "vault"
brew "vim"
brew "watch"
brew "wget"
brew "wireguard-tools" # need `wg` to generate public & private keys
brew "youtube-dl"
brew "yq"
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-git-prompt"
brew "zsh-lovers"
brew "zsh-syntax-highlighting"

brew "cloudfoundry/tap/cf-cli@8"
# brew "cloudfoundry/tap/credhub-cli" # The x86_64 architecture is required for this software.
brew "git-duet/tap/git-duet"
brew "golangci/tap/golangci-lint"
brew "pivotal-cf/om/om"

cask "disk-inventory-x" # who's using up all my space?
cask "firefox"
cask "flycut"
cask "font-hack-nerd-font"
cask "gimp"
cask "google-chrome"
cask "google-cloud-sdk"
cask "google-drive"
cask "graphiql"
cask "handbrake"
cask "istat-menus"
cask "iterm2"
cask "jetbrains-toolbox"
cask "makemkv"
cask "messenger" # Facebook messenger to sell things on FB Marketplace
cask "postman" # Used for troubleshooting SERC's n8n.io → PDK migration
cask "rancher"
cask "rectangle"
cask "skype"
cask "slack"
cask "steam"

# cask "vagrant" # Docker has largely supplanted vagrant # This package requires Rosetta 2 to be installed.
# cask "virtualbox" # Error: Cask virtualbox depends on hardware architecture being one of [{:type=>:intel, :bits=>64}], but you are running {:type=>:arm, :bits=>64}.
cask "visual-studio-code"
cask "vlc"
# cask "vmware-fusion" # Because it's cool; install manually to avoid "chown: /Applications/VMware Fusion.app/Contents/CodeResources: Operation not permitted"
cask "whatsapp"
cask "wireshark"
cask "xquartz"
cask "zoom"
