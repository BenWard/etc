# @benward/etc

Dotfiles, scripts and configs for re-use across machines.

* `bash` is our preferred shell; Bash and zsh share managed configuration
* Uses Chezmoi as the dotfile manager
* `just` as the command runner
* homebrew is the system-wide package manager, and Brewfile install utilities I use on every machine.

## chezmoi

The repo root contains a `.chezmoiroot` file that points Chezmoi at `home/` as the source-state root. That keeps the source tree separate from repo-only files.

## Editing Workflow

1. Run `just diff` to ensure not drift has occured.

If a managed file is edited directly in `$HOME`, pull those edits back into the
source state before re-applying:

```sh
just reverse            # all modified files
just reverse ~/.bashrc  # scope to specific targets
```

`reverse` runs `chezmoi re-add` and then presents the incoming changes as
`git add -p` hunks ([y]es/[n]o/[a]ll/[d]o not this file). Selected hunks stay
staged in the source; rejected hunks are discarded. Templates and encrypted
files cannot be reverse-applied automatically and are reported for manual
editing. The source tree must be clean before running it.

Edit source files in this repo, then run:

```sh
just diff
just apply
```

## Tooling

`just init` runs `tools/init.py`, which imports `tomllib` (Python 3.11+). The
recipe invokes `"$(brew --prefix)/bin/python3"` rather than a bare `python3` so
an activated project venv on `PATH` can't shadow it with an older interpreter.

## Prompt

Starship is configured in `home/dot_config/starship.toml.tmpl` to preserve the old prompt shape:

```text
[HH:MM] ~user@host ~/path#branch ± $
[HH:MM] ~user@host ~/path#branch = $
```

The marker is `±` when the repo has changes and `=` when the repo is clean.

## History

Atuin is configured in `home/dot_config/atuin/config.toml` with `auto_sync = false`. No cloud account, sync key, sync address is configured by this repo.

`hist` opens Atuin search; `hist <query>` uses fzf and an editable command prompt.
Bash uses Readline; zsh fills the next command line.

Shared modules live in `home/dot_dotfiles_lib/shell/`; shell-specific adapters
live in sibling `bash/` and `zsh/` directories. Use `just test-shells` for isolated
behavior tests and `just smoke-shells` for real integrations in temporary PTYs.
Use `just diff-shells` and `just apply-shells` when unrelated managed files have
local drift. See `docs/v2.md` for startup and override behavior.

## Validation Notes

After editing the repo, run:

```sh
just --list
just doctor
just diff
just dry-run
just check-bundle
```
