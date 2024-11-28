tap "cloudfoundry/tap"
tap "git-duet/tap"
tap "golangci/tap"
tap "homebrew/bundle"
tap "homebrew/services"
brew "autojump" # replaces "fasd", which has an archived upstream repo
brew "automake"
brew "awscli"
brew "azure-cli" # for terraforming ns-azure
brew "berkeley-db@5" # for Python module gutenberg
brew "bison"
brew "bitwarden-cli" # LastPass is dead, long live Bitwarden!
brew "bosh-cli" # commenting-out to avoid "Error: key not found: "cloudfoundry/tap/bosh-cli"
brew "cdrtools" # ln -s $(brew --prefix)/bin/{mkisofs,genisoimage} # fixes 127 -sh: genisoimage: command not found
brew "cfssl"
brew "chruby"
brew "cloc" # count lines of code to figure out how much code we'll need to write
brew "cmake"
brew "credhub-cli"
brew "dependency-check"
brew "direnv"
brew "docker" # CLI only
brew "docker-credential-helper" # fixes `docker buildx` → "exec: "docker-credential-osxkeychain": executable file not found in $PATH"
brew "etcd" # for sslip.io backend database
brew "fd"
brew "gh" # GitHub CLI, needed to delete many of my no-longer-needed forked repos
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
brew "packer" # needed for ops-manager/vm, to create OM VMs
brew "postgresql@13", restart_service: true # Operations Manager
brew "python"
brew "python@3.8" # needed for Google Cloud SDK https://cloud.google.com/sdk/gcloud/reference/topic/startup
brew "python@3.11" # needed for vLLM
brew "qemu" # so I can convert MS Windows VHDX to a VMDK to run VMware Fusion
brew "qrencode"
brew "readline"
brew "ripgrep"
brew "ruby-install"
brew "rust" # needed by Python package tiktoken for evaluation LLM chess models
brew "stockfish" # needed for evaluation LLM chess models
brew "terraform"
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
cask "visual-studio-code"
cask "vlc"
cask "whatsapp"
cask "wireshark"
cask "zoom"
