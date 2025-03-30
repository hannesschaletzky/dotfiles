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
AWS_ACCOUNT_ID="593793026870"
AWS_ECR_URL=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
AWS_PROFILE_NAME="cli-profile"
# 593793026870.dkr.ecr.eu-central-1.amazonaws.com

# create repo 
ecr_create() {
  local name
  name=$(get_docker_name) || return 1

  aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ECR_URL
  aws ecr create-repository --repository-name $name --region $AWS_REGION --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE
  aws ecr set-repository-policy --repository-name $name --policy-text file://~/repos/0_customers/blu/blu_integrations/ecr_repo_policy.json
}

# run docker image locally
docker-local() {
  local name
  name=$(get_docker_name) || return 1

  # check if docker-compose.yml exists
  if [[ ! -f "docker-compose.yml" ]]; then
    echo "Error: docker-compose.yml file not found." >&2
    return 1
  fi

  docker-compose down
  docker-compose build
  docker-compose up
}

# deploy to ecr
docker-deploy-to-ecr() {
  local name
  name=$(get_docker_name) || return 1

  allowed_names=("blu_intune" "blu_outlook" "blu_toolbox")
  if [[ ! " ${allowed_names[@]} " =~ " $name " ]]; then
    echo "Error: '$name' is not allowed to be deployed to ecr." >&2
    return 1
  fi

  aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ECR_URL
  docker build \
    -f Dockerfile.prod \
    --no-cache \
    --platform linux/amd64 \
    -t $name .
  docker tag $name $AWS_ECR_URL/"$name":latest
  docker push $AWS_ECR_URL/"$name":latest
}

# deploys to docker hub
DOCKER_HUB_ACCOUNT_NAME="hannesschaletzky"
docker-deploy-to-dockerhub() {
  local name version
  name=$(get_docker_name) || return 1
  version=$(node -p "require('./package.json').version")

  if [[ "$name" != "blu_mid_server" ]]; then
    echo "only 'blu_mid_server' can be deployed to dockerhub." >&2
    return 1
  fi
  if [[ -z "$version" ]]; then
    echo "Error: version not found in package.json." >&2
    return 1
  fi

  docker build \
    -f Dockerfile.prod \
    --no-cache \
    --platform linux/amd64 \
    -t $name .
  
  docker tag $name $DOCKER_HUB_ACCOUNT_NAME/"$name":latest
  docker tag $name $DOCKER_HUB_ACCOUNT_NAME/"$name":v$version
  
  docker push $DOCKER_HUB_ACCOUNT_NAME/"$name":latest
  docker push $DOCKER_HUB_ACCOUNT_NAME/"$name":v$version

  echo "✅ published v$version to $DOCKER_HUB_ACCOUNT_NAME/$name"
}

# -> publish mid server
pms() {
  git add .
  git commit -m "edits"
  npm version patch
  git push origin main
  git push origin --tags
}


upgradeAllDependecies() {
  npx npm-check-updates -u
  npm install
}

# Function to select an environment
select_environment() {
  local ENVIRONMENTS=("development" "demo" "test" "e2e" "qa" "production")

  # Use fzf for selection
  local SELECTED_ENV=$(printf "%s\n" "${ENVIRONMENTS[@]}" | fzf --prompt="Select an environment: ")

  # Check if a valid environment was selected
  if [ -z "$SELECTED_ENV" ]; then
    echo "No environment selected. Exiting..."
    exit 1
  fi

  echo "$SELECTED_ENV"  # Return selected environment
}

# use like this: createMidServerResources tal-oil-it
createMidServerResources() {
  if [ -z "$1" ]; then
    echo "Error: customer name is required as the first argument." >&2
    return 1
  fi

  CUSTOMER=$1
  ENV=$(select_environment)
  POLICY_NAME=$(getPolicyName "$CUSTOMER" "$ENV")
  GROUP_NAME=$(getGroupName "$CUSTOMER" "$ENV")
  USER_NAME=$(getUserName "$CUSTOMER" "$ENV")
  BUCKET_NAME=$(getBucketName "$CUSTOMER" "$ENV")
  echo "Customer: $CUSTOMER"
  echo "Env: $ENV"
  echo "Policy: $POLICY_NAME"
  echo "Group: $GROUP_NAME"
  echo "User: $USER_NAME"
  echo "Bucket: $BUCKET_NAME"


  echo "Creating SQS Queues for customer: $CUSTOMER"
  for queue_type in in out;
  do
    QUEUE_NAME="${CUSTOMER}_${ENV}_${queue_type}.fifo"
    aws sqs create-queue \
    --queue-name "${QUEUE_NAME}" \
    --attributes '{
      "FifoQueue":"true",
      "ContentBasedDeduplication":"true",
      "MessageRetentionPeriod":"1209600", 
      "VisibilityTimeout":"30",
      "DelaySeconds":"0",
      "ReceiveMessageWaitTimeSeconds":"0",
      "MaximumMessageSize":"262144",
      "DeduplicationScope":"messageGroup",
      "FifoThroughputLimit": "perMessageGroupId"
    }' \
    --profile $AWS_PROFILE_NAME
  echo "✅ ${QUEUE_NAME} created"
  done
  
  # create S3 bucket
  aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${AWS_REGION}" \
  --create-bucket-configuration LocationConstraint="${AWS_REGION}" \
  --profile $AWS_PROFILE_NAME
  echo "✅ S3 bucket created: ${BUCKET_NAME}"

  # create IAM Policy
  POLICY_DOCUMENT=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Action": [
                "sqs:DeleteMessage",
                "sqs:ReceiveMessage"
            ],
            "Resource": "arn:aws:sqs:${AWS_REGION}:${AWS_ACCOUNT_ID}:${CUSTOMER}_${ENV}_in.fifo"
        },
        {
            "Sid": "2",
            "Effect": "Allow",
            "Action": [
                "sqs:SendMessage"
            ],
            "Resource": "arn:aws:sqs:${AWS_REGION}:${AWS_ACCOUNT_ID}:${CUSTOMER}_${ENV}_out.fifo"
        },
        {
            "Sid": "3",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        }
    ]
}
EOF
)

  # save policy JSON to a file
  POLICY_FILE="/tmp/${POLICY_NAME}.json"
  echo "$POLICY_DOCUMENT" > "$POLICY_FILE"

  # create IAM Policy
  POLICY_ARN=$(aws iam create-policy \
    --policy-name ${POLICY_NAME} \
    --policy-document "file://${POLICY_FILE}" \
    --query 'Policy.Arn' --output text \
    --profile $AWS_PROFILE_NAME)
  echo "✅ IAM Policy created: ${POLICY_ARN}"

  # create IAM User Group
  aws iam create-group \
    --group-name $GROUP_NAME \
    --profile $AWS_PROFILE_NAME
  echo "✅ IAM Group created: $GROUP_NAME"

  # attach policy to group
  aws iam attach-group-policy \
    --group-name $GROUP_NAME \
    --policy-arn $POLICY_ARN \
    --profile $AWS_PROFILE_NAME
  echo "✅ attach-policy-to-group: $GROUP_NAME"  

  # create IAM User
  aws iam create-user \
    --user-name $USER_NAME \
    --profile $AWS_PROFILE_NAME
  aws iam add-user-to-group \
    --user-name $USER_NAME \
    --group-name $GROUP_NAME \
    --profile $AWS_PROFILE_NAME
  echo "✅ add-user-to-group: $USER_NAME"
}

deleteMidServerResources() {
  if [ -z "$1" ]; then
    echo "Error: customer name is required as the first argument." >&2
    return 1
  fi

  CUSTOMER=$1
  ENV=$(select_environment)
  POLICY_NAME=$(getPolicyName "$CUSTOMER" "$ENV")
  GROUP_NAME=$(getGroupName "$CUSTOMER" "$ENV")
  USER_NAME=$(getUserName "$CUSTOMER" "$ENV")
  BUCKET_NAME=$(getBucketName "$CUSTOMER" "$ENV")
  echo "Customer: $CUSTOMER"
  echo "Env: $ENV"
  echo "Policy: $POLICY_NAME"
  echo "Group: $GROUP_NAME"
  echo "User: $USER_NAME"
  echo "Bucket: $BUCKET_NAME"

  for queue_type in in out;
  do
    QUEUE_NAME="${CUSTOMER}_${ENV}_${queue_type}.fifo"
    aws sqs delete-queue \
      --queue-url https://sqs.${AWS_REGION}.amazonaws.com/${AWS_ACCOUNT_ID}/${QUEUE_NAME} \
      --profile $AWS_PROFILE_NAME
  done

  # delete s3 bucket
  aws s3 rm s3://"$BUCKET_NAME" --recursive --profile $AWS_PROFILE_NAME
  aws s3api delete-bucket \
    --bucket $BUCKET_NAME \
    --region $AWS_REGION \
    --profile $AWS_PROFILE_NAME
  echo "✅ delete-bucket: $BUCKET_NAME"


  aws iam remove-user-from-group \
    --user-name $USER_NAME \
    --group-name $GROUP_NAME \
    --profile $AWS_PROFILE_NAME
  echo "✅ remove-user-from-group: $USER_NAME"

  aws iam delete-user \
    --user-name $USER_NAME \
    --profile $AWS_PROFILE_NAME
  echo "✅ delete-user: $USER_NAME"

  aws iam detach-group-policy \
    --group-name $GROUP_NAME \
    --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME} \
    --profile $AWS_PROFILE_NAME
  echo "✅ detach-group-policy: $GROUP_NAME"

  aws iam delete-group \
    --group-name $GROUP_NAME \
    --profile $AWS_PROFILE_NAME
  echo "✅ delete-group: $GROUP_NAME"

  aws iam delete-policy \
    --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME} \
    --profile $AWS_PROFILE_NAME
  echo "✅ delete-policy: $POLICY_NAME"
}

getBucketName() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Both customer name and environment are required as input parameters." >&2
    return 1
  fi

  CUSTOMER=$1
  ENV=$2

  sanitize_string() {
    echo "$1" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]'
  }

  CUSTOMER_SAN=$(sanitize_string "$CUSTOMER")
  # Optional log:
  >&2 echo "🔧 sanitized customer name: $CUSTOMER_SAN"

  echo "blu-mid-server-${CUSTOMER_SAN}-${ENV}"
}


getPolicyName() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Both customer name and environment are required as input parameters." >&2
    return 1
  fi

  CUSTOMER=$1
  ENV=$2

  POLICY_NAME="mid_server_${CUSTOMER}_${ENV}_policy"
  echo "$POLICY_NAME"
}

getGroupName() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Both customer name and environment are required as input parameters." >&2
    return 1
  fi

  CUSTOMER=$1
  ENV=$2

  GROUP_NAME="mid_server_${CUSTOMER}_${ENV}"
  echo "$GROUP_NAME"
}

getUserName() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Both customer name and environment are required as input parameters." >&2
    return 1
  fi

  CUSTOMER=$1
  ENV=$2

  USER_NAME="mid_server_${CUSTOMER}_${ENV}"
  echo "$USER_NAME"
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