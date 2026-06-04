# @benward/etc

Dotfiles, scripts and configs for re-use across machines.

* `bash` is our preferred shell
* Uses Chezmoi as the dotfile manager
* `just` as the command runner
* homebrew is the system-wide package manager, and Brewfile install utilities I use on every machine.

## chezmoi

The repo root contains a `.chezmoiroot` file that points Chezmoi at `home/` as the source-state root. That keeps the source tree separate from repo-only files.

## Editing Workflow

1. Run `just diff` to ensure not drift has occured.

If a managed file is edited directly in `$HOME`, bring it back into the source state:
`chezmoi --source "$(pwd)" re-add ~/.bashrc`

Edit source files in this repo, then run:

```sh
just diff
just apply
```

## Prompt

Starship is configured in `home/dot_config/starship.toml.tmpl` to preserve the old prompt shape:

```text
[HH:MM] ~user@host ~/path#branch ± $
[HH:MM] ~user@host ~/path#branch = $
```

The marker is `±` when the repo has changes and `=` when the repo is clean.

## History

Atuin is configured in `home/dot_config/atuin/config.toml` with `auto_sync = false`. No cloud account, sync key, sync address is configured by this repo.

`hist` is an alias for `atuin search`.

## Validation Notes

After editing the repo, run:

```sh
just --list
just doctor
chezmoi --source "$(pwd)" diff
chezmoi --source "$(pwd)" apply --dry-run --verbose
brew bundle check --file Brewfile --verbose
```
