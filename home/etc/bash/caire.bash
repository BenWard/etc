# Caire path extensions

# Add infra utils
export PATH="$PATH:$HOME/code/caire-infra/bin"

# Functions useful for Caire workflows

# Push the current branch to our `development` branch, which will deploy
# to the dev environment.
function push-to-dev {
    # get the current git branch name
    local branch=$(git rev-parse --abbrev-ref HEAD)
    
    # if no branch, then exit with error
    if [ -z "$branch" ]; then
        echo "Error: Not on a git branch."
        return 1
    fi

    git push --force -u origin $branch:development
}

# Caire Claude Code
export CLAUDE_CODE_USE_BEDROCK=1
