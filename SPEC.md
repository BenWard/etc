# Shared Bash and zsh configuration

## Summary

Developer tools frequently launch zsh even though Bash is preferred. Manage both
shells through Chezmoi with shared helpers and equivalent interactive workflows.
Retain the account login shell and developer-tool preferences.

## Startup and architecture

- Shared `.sh` modules target Bash and zsh, not arbitrary POSIX sh. Keep native
  adapters for completion, history editing, shell options, and terminal hooks.
- `.zshenv` provides quiet PATH setup and mise shims for non-interactive commands.
  `.zprofile` restores precedence after macOS startup and preserves OrbStack.
  `.zshrc` loads interactive helpers and integrations.
- Existing Bash entrypoints retain their behavior, with explicit interactive
  detection. Non-interactive login Bash uses shims; plain Bash inherits PATH.
- Share Homebrew defaults, language helpers, Git/Docker helpers, and application
  wrappers. Preserve argument boundaries and handle glob/PID results explicitly.
- Select native tool initialization using the running interpreter, not `$SHELL`.
  Initialize Starship before Atuin and load bash-preexec only for Bash.
  Atuin hooks and fzf keybindings require terminal input, including when a
  developer tool explicitly requests an interactive shell with piped stdin.
- Preserve native zsh expansion rules; provide Emacs keys and case-insensitive
  completion. Keep the existing Starship configuration and preserve `TERM`.

## History and reload behavior

- Use one local Atuin database, with cloud sync disabled. Keep independent native
  history files. Zsh uses append mode, ignores duplicates/leading spaces, and
  retains 50,000 in-memory and 100,000 saved entries.
- Share `hist` search logic. Bash edits selections at its existing `run:` prompt;
  zsh fills the next command line. Cancellation never executes a selection.
- Import existing zsh history with a marker independent of the Bash import.
  Write the zsh marker only on success; absent history remains eligible later.
- `resource` reloads in-process, preserving variables and jobs. Avoid duplicate
  PATH entries, hooks, and completion initialization. Initialization-code changes
  require a new shell; shared settings and helper changes reload immediately.
- Load optional `~/.extras.sh`, then the active shell's `~/.extras.bash` or
  `~/.extras.zsh`. Do not run arbitrary overrides in non-interactive `.zshenv`.

## Migration

- Back up current startup files and shell libraries before scoped application.
- Preserve machine-local `SKIP_RESOURCE_CHECK=1` in `~/.extras.sh`.
- Preserve local mise tool versions and unrelated application changes by applying
  only shell targets. Remove only explicitly superseded managed Bash modules.
- Keep maintenance scripts in Bash and `dcshell` launching Bash in containers.
- Target installed Homebrew Bash and macOS zsh. No new packages or shell framework.

## Acceptance

- Exercise interactive/login startup in both shells and quiet non-interactive
  zsh startup, including runtime shim availability.
- Test repeated sourcing and nested shells, native tool selection/order, absent
  optional tools, override precedence, and custom mise data directories.
- Check helper arguments containing spaces, absent arguments, Sublime project
  discovery with zero/multiple matches, and multiple PIDs from `killport`.
- Test history selection/cancellation, import retries, and separate markers.
- Exercise real integrations in temporary PTYs: prompt rendering, reload hooks,
  editable selections, and Tab completion.
- Run Just recipes for doctor, Chezmoi diff/dry-run, and Brewfile validation.
  Verify installed shell startup after scoped application.
