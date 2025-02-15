# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$HOME/.yarn/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/hannesschaletzky/.oh-my-zsh"

# Java runtime
export JAVA_HOME=$(/usr/libexec/java_home -v 22.0.1)
export PATH=$JAVA_HOME/bin:$PATH

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

alias openCfg="code ~/.zshrc"
alias seePort3000="lsof -i tcp:3000"
# kill with kill -9 "PID"

kill_processes_on_5000() {
  pids=$(lsof -t -i tcp:5000)
  
  if [ -z "$pids" ]; then
    echo "No processes found on TCP port 5000."
  else
    echo $pids | xargs kill -9
    echo "Killed processes on TCP port 5000."
  fi
}

alias jvb="jest --verbose --silent=false"
alias c="clear"
alias n1="npm run build"
alias n2="npm run publish:patch"

# token for private org packages blu_systems
export NPM_TOKEN=

# update blue shared
ubs() {
  echo "update @blu_systems/shared"
  npm install @blu_systems/shared@latest 
}

get_docker_name() {
  # check if docker.txt exists
  if [[ -f "docker.txt" ]]; then
    local docker_name
    docker_name=$(<docker.txt) 
    echo "docker.txt: $docker_name" >&2
    echo $docker_name
  else
    echo "Error: docker.txt file not found." >&2
    return 1
  fi
}

AWS_REGION="eu-central-1"
ACCOUNT_ID="_"
AWS_URL=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
# _.dkr.ecr.eu-central-1.amazonaws.com

# create repo 
ecr_create() {
  check_input $1 || return 1

  aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_URL
  aws ecr create-repository --repository-name $1 --region $AWS_REGION --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE
  aws ecr set-repository-policy --repository-name $1 --policy-text file://~/repos/0_customers/blu/blu_integrations/ecr_repo_policy.json
}

# docker test
dote() {
  local name
  name=$(get_docker_name) || return 1

  docker build --platform linux/amd64 -t $name .
  docker-compose up
}

# docker deploy
dode() {
  local name
  name=$(get_docker_name) || return 1

  aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_URL
  docker build --platform linux/amd64 -t $name .
  docker tag $name $AWS_URL/"$name":latest
  docker push $AWS_URL/"$name":latest
}






# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git gitfast last-working-dir common-aliases alias-finder history-substring-search)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# nodenv
export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init - zsh)"