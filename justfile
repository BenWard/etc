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

# Import existing Bash and zsh history into Atuin (one-time, idempotent).
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

# Test shell startup, helpers, and history migration in isolated home directories.
test-shells:
    "$(brew --prefix)/bin/python3" "{{source_dir}}/tools/test-shells.py"

# Exercise real installed integrations in temporary homes with terminal input.
smoke-shells:
    "$(brew --prefix)/bin/python3" "{{source_dir}}/tools/smoke-shells.py"

# Verify deployed startup files against the current user's installed tools.
check-installed-shells:
    "$(brew --prefix)/bin/python3" "{{source_dir}}/tools/smoke-shells.py" --installed

# Preview changes without applying; suitable for checking unrelated local drift.
dry-run:
    chezmoi --source "{{source_dir}}" apply --dry-run --verbose --force

# Check installed packages without changing them.
check-bundle:
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "{{source_dir}}/Brewfile" --verbose

# Preview only shell files. Superseded Bash modules are included for removal.
diff-shells:
    chezmoi --source "{{source_dir}}" diff --recursive ~/.bashrc ~/.bash_profile ~/.zshenv ~/.zprofile ~/.zshrc ~/.dotfiles_lib/bash ~/.dotfiles_lib/shell ~/.dotfiles_lib/zsh

# Apply shell configuration without overwriting unrelated managed files.
apply-shells *ARGS:
    chezmoi --source "{{source_dir}}" apply {{ARGS}} ~/.bashrc ~/.bash_profile ~/.zshenv ~/.zprofile ~/.zshrc ~/.dotfiles_lib/bash ~/.dotfiles_lib/shell ~/.dotfiles_lib/zsh
