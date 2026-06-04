# Enter a running docker container in a bash shell
function dcshell {
    local container=$1
    if [ -z "$container" ]; then
        echo "Error: Container name is required."
        return 1
    fi

    docker compose exec $container bash
}

# Run a command inside a named docker container.
function dcrun {
    local container=$1
    shift
    if [ -z "$container" ]; then
        echo "Error: Container name is required."
        return 1
    fi
    
    docker compose run \
      --remove-orphans \
      --build $container \
      "$@"
}

# Run pytest inside named docker container.
# Arguments:
#   $1 the name of the container to run tests in
#   $2 the path to the tests directory (default: .)
function dcpytest {
    local container=$1
    local test_dir=${2:-.}
    
    if [ -z "$container" ]; then
        echo "Error: Container name is required."
        return 1
    fi

    dcrun $container poetry run pytest --cov --cov-fail-under=75 $test_dir -v
}