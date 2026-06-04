set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

source_dir := justfile_directory()
default:
    @just --list

# Install Homebrew packages and apply the Chezmoi source state.
install:
    brew bundle install --file "{{source_dir}}/Brewfile"
    chezmoi init --source "{{source_dir}}"
    chezmoi --source "{{source_dir}}" apply --force
    bash "{{source_dir}}/tools/doctor.bash" "{{source_dir}}" "{{source_dir}}/home"
    bash "{{source_dir}}/tools/migrate-history.bash"

# Apply managed dotfiles to $HOME.
apply:
    chezmoi --source "{{source_dir}}" apply

# Show the home-directory changes Chezmoi would make.
diff:
    chezmoi --source "{{source_dir}}" diff

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
