set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

source_dir := justfile_directory()
default:
    @just --list

# Install Homebrew packages and apply the Chezmoi source state.
install:
    brew bundle install --file "{{source_dir}}/Brewfile"
    chezmoi init --source "{{source_dir}}"
    just --justfile "{{source_dir}}/justfile" --working-directory "{{source_dir}}" init
    chezmoi --source "{{source_dir}}" apply --force
    bash "{{source_dir}}/tools/doctor.bash" "{{source_dir}}" "{{source_dir}}/home"
    bash "{{source_dir}}/tools/migrate-history.bash"

# Use Homebrew's python3 explicitly so an active project venv on PATH can't
# shadow it; init.py needs tomllib, which only ships with Python 3.11+.

# Create or update the machine-local Chezmoi config.
init:
    $(brew --prefix)/bin/python3 "{{source_dir}}/tools/init.py" "{{source_dir}}"

# Apply managed dotfiles to $HOME.
apply: init
    chezmoi --source "{{source_dir}}" apply

# Show the home-directory changes Chezmoi would make.
diff:
    chezmoi --source "{{source_dir}}" diff

# Pull local $HOME changes back into the source, choosing hunks like git add -p.
reverse *ARGS: init
    bash "{{source_dir}}/tools/reverse-apply.bash" "{{source_dir}}" {{ARGS}}

# Check required tools, shell startup, Chezmoi state, and Brewfile status.
doctor:
    bash "{{source_dir}}/tools/doctor.bash" "{{source_dir}}" "{{source_dir}}/home"

# Import existing bash history into atuin (one-time, idempotent).
migrate-history:
    bash "{{source_dir}}/tools/migrate-history.bash"

# Update packages, re-apply dotfiles, and report language tool updates.
update:
    brew update
    brew bundle install --file "{{source_dir}}/Brewfile"
    chezmoi --source "{{source_dir}}" apply
    mise plugins update || true
    mise outdated || true
    brew outdated || true
