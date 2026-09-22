#!/usr/bin/env python3
"""Shell behavior tests; all startup/history writes stay in temporary homes."""
import os
from pathlib import Path
import shutil
import pty
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SHELLS = {"bash": shutil.which("bash"), "zsh": shutil.which("zsh")}
OPTIONAL = "mise fzf zoxide starship atuin thefuck npm zinc VBoxManage"
STUB = r'''#!/bin/bash
name=${0##*/}
printf '%s %s\n' "$name" "$*" >> "$TEST_LOG"
case "$name:$1" in
  mise:activate|mise:hook-env) printf '_dotfiles_prepend_path "$HOME/runtime/bin"\n' ;;
  fzf:--bash|fzf:--zsh|zoxide:init|starship:init|atuin:init) : ;;
  thefuck:--alias) printf 'f() { :; }\n' ;;
  npm:completion) printf '_npm_completion() { :; }\n'
    printf 'if [ -n "${ZSH_VERSION:-}" ]; then compdef _npm_completion npm; else complete -F _npm_completion npm; fi\n' ;;
  atuin:import) [ "${TEST_IMPORT_FAIL:-}" != "$2" ] ;;
  atuin:search) printf '%s\n' "${TEST_CHOICE:-echo picked}" ;;
  fzf:*) [ -z "${TEST_CANCEL:-}" ] || exit 130
    printf '%s\n' "${TEST_CHOICE:-echo picked}" ;;
  *) printf '<%s>' "$@"; printf '\n' ;;
esac
'''


class ShellTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-shells-")
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name) / "home with spaces"
        self.home.mkdir()
        shutil.copytree(ROOT / "home/dot_dotfiles_lib", self.home / ".dotfiles_lib")
        for name in ("bashrc", "bash_profile", "zshenv", "zprofile", "zshrc"):
            shutil.copyfile(ROOT / f"home/dot_{name}", self.home / f".{name}")
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        for name in OPTIONAL.split() + ["subl", "code", "nova", "docker", "python3", "sudo"]:
            self.stub(name, STUB)
        prefix = self.home / "brew"
        (prefix / "etc/profile.d").mkdir(parents=True)
        (prefix / "etc/profile.d/bash-preexec.sh").write_text(
            'printf "preexec\\n" >> "$TEST_LOG"\n'
        )
        (prefix / "share/zsh/site-functions").mkdir(parents=True)
        self.log = self.home / "calls.log"
        self.env = {
            "HOME": str(self.home), "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            "BREWDIR": str(prefix), "TERM": "xterm-256color",
            "SHELL": "/deliberately/wrong/shell", "TEST_LOG": str(self.log),
            "LC_ALL": "C", "USER": os.environ.get("USER", "test"),
            "BASH_SILENCE_DEPRECATION_WARNING": "1",
        }

    def stub(self, name, content):
        target = self.bin / name
        target.write_text(content)
        target.chmod(0o755)

    def run_shell(self, shell, code, flags="-ic", env=None):
        terminal = pty.openpty() if 'i' in flags else None
        try:
            result = subprocess.run(
                [SHELLS[shell], flags, code], env=env or self.env,
                stdin=terminal[1] if terminal else subprocess.DEVNULL,
                cwd=self.home, text=True, capture_output=True, timeout=30,
            )
        finally:
            if terminal:
                for fd in terminal:
                    os.close(fd)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        # Bash without a PTY reports these two expected job-control warnings.
        errors = [line for line in result.stderr.splitlines()
                  if "cannot set terminal process group" not in line
                  and "no job control in this shell" not in line]
        self.assertEqual(errors, [], result.stderr)
        return result.stdout

    def test_syntax(self):
        for shell, executable in SHELLS.items():
            paths = list((ROOT / "home/dot_dotfiles_lib/shell").glob("*.sh"))
            paths += list((ROOT / f"home/dot_dotfiles_lib/{shell}").glob(f"*.{shell}"))
            for path in paths:
                result = subprocess.run([executable, "-n", str(path)], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, f"{path}: {result.stderr}")

    def test_startup_and_reload(self):
        for shell in SHELLS:
            for flags in ("-ic", "-lic"):
                with self.subTest(shell=shell, flags=flags):
                    self.log.unlink(missing_ok=True)
                    result = self.run_shell(shell, r'''
                        before=$PATH
                        session_value=retained
                        resource
                        resource
                        [[ "$session_value" = retained ]] || exit 10
                        [[ "$TERM" = xterm-256color ]] || exit 11
                        [[ "$PATH" = "$before" ]] || exit 12
                        [[ "$WORKTREE_ROOT" = "$HOME/Code/_worktrees" ]] || exit 13
                        type hist nr pr wt github dcrun >/dev/null || exit 14
                        printf '%s\n' "$DOTFILES_SHELL"
                    ''', flags)
                    self.assertEqual(result.strip(), shell)
                    calls = self.log.read_text().splitlines()
                    for call in (f"mise activate {shell}", f"fzf --{shell}",
                                 f"zoxide init {shell}", f"starship init {shell}",
                                 f"atuin init {shell}", "thefuck --alias f"):
                        self.assertEqual(calls.count(call), 1, calls)
                    self.assertLess(calls.index(f"starship init {shell}"), calls.index(f"atuin init {shell}"))
                    if shell == "bash":
                        self.assertLess(calls.index("preexec"), calls.index("atuin init bash"))
                    else:
                        self.assertNotIn("preexec", calls)

    def test_noninteractive_startup(self):
        for shell, flags in (("zsh", "-c"), ("zsh", "-lc"), ("bash", "-lc")):
            with self.subTest(shell=shell, flags=flags):
                self.log.unlink(missing_ok=True)
                output = self.run_shell(shell, r'''
                    [[ "$PATH" = "$HOME/.local/bin:$HOME/.local/share/mise/shims:"* ]] || exit 10
                    if type hist >/dev/null 2>&1; then exit 11; fi
                    printf 'quiet\n'
                ''', flags)
                self.assertEqual(output, "quiet\n")
                self.assertFalse(self.log.exists(), "Non-interactive startup invoked a tool")

    def test_interactive_without_terminal(self):
        for shell in SHELLS:
            self.log.unlink(missing_ok=True)
            result = subprocess.run([SHELLS[shell], '-ic', 'type hist >/dev/null'],
                env=self.env, cwd=self.home, stdin=subprocess.DEVNULL,
                capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('atuin init', self.log.read_text())
            self.assertNotIn(f'fzf --{shell}', self.log.read_text())

    def test_custom_mise_directory_and_path_deduplication(self):
        env = {**self.env, "MISE_DATA_DIR": str(self.home / "custom mise")}
        result = self.run_shell("zsh", r'''
            source "$HOME/.zshenv"
            printf '%s\n' "$PATH"
        ''', "-c", env)
        parts = result.strip().split(":")
        self.assertEqual(parts[1], str(self.home / "custom mise/shims"))
        self.assertEqual(len(parts), len(set(parts)))

    def test_helpers_preserve_arguments(self):
        for shell in SHELLS:
            with self.subTest(shell=shell):
                output = self.run_shell(shell, '''
                    code 'some dir' --wait
                    nova 'some dir'
                    subl 'project file' --new-window
                    http 9000 --bind '127.0.0.1'
                    sudohttp
                    dcrun 'service name' printf '%s' 'two words'
                    dcshell 'service name'
                    dcpytest 'service name' 'test dir'
                    if dcrun 2>/dev/null; then exit 1; fi
                ''')
                self.assertIn('<some dir><--wait>', output)
                self.assertIn('<open><some dir><--no-wait>', output)
                self.assertIn('<project file><--new-window>', output)
                self.assertIn('<-m><http.server><9000><--bind><127.0.0.1>', output)
                self.assertIn('<python3><-m><http.server>', output)
                self.assertIn('<compose><run><--remove-orphans><--build><service name><printf><%s><two words>', output)
                self.assertIn('<compose><exec><service name><bash>', output)
                self.assertIn('<test dir><-v>', output)

    def test_sublime_project_discovery(self):
        for count in (0, 1, 2):
            if count:
                (self.home / f"project {count}.sublime-project").touch()
            for shell in SHELLS:
                output = self.run_shell(shell, 'subl')
                if not count:
                    self.assertEqual(output, '<.>\n')
                else:
                    for n in range(1, count + 1):
                        self.assertIn(f'<./project {n}.sublime-project>', output)

    def test_killport_handles_multiple_pids(self):
        for shell in SHELLS:
            result = self.run_shell(shell, r'''
                lsof() { printf '101\n202\n'; }
                kill() { printf '<%s>' "$@"; }
                killport 8000
            ''')
            self.assertEqual(result, '<101><202>')

    def test_overrides_and_nested_shell(self):
        (self.home / ".extras.sh").write_text('EXTRA_ORDER=shared\n')
        for shell in SHELLS:
            (self.home / f".extras.{shell}").write_text(f'EXTRA_ORDER="$EXTRA_ORDER:{shell}"\n')
            result = self.run_shell(shell, 'resource; printf "%s\\n" "$EXTRA_ORDER"')
            self.assertEqual(result.strip(), f'shared:{shell}')
            result = self.run_shell(shell,
                f'''{SHELLS[shell]} -ic 'printf "%s\\n" "$DOTFILES_SHELL"' ''')
            self.assertEqual(result.strip(), shell)

    def test_missing_integrations(self):
        for shell in SHELLS:
            # Override discovery, not shell builtins, to simulate absent packages
            # even when the host has Homebrew's real commands installed.
            (self.home / ".dotfiles_lib/shell/env.sh").write_text('''
                source "$HOME/.dotfiles_lib/shell/paths.sh"
                command() {
                  if [[ "$1" = -v ]]; then
                    case "$2" in
                      mise|fzf|zoxide|starship|atuin|thefuck|npm) return 1 ;;
                    esac
                  fi
                  builtin command "$@"
                }
            ''')
            result = self.run_shell(shell, 'resource; [[ -n "$PS1" ]] || exit 1; printf fallback')
            self.assertEqual(result, 'fallback')

    def test_history_cancel_and_selection(self):
        for shell in SHELLS:
            code = '''
                _dotfiles_hist_edit() { printf 'edit:<%s>\\n' "$1"; }
                hist picked
            '''
            output = self.run_shell(shell, code)
            self.assertEqual(output, 'edit:<echo picked>\n')
            output = self.run_shell(shell, code, env={**self.env, 'TEST_CANCEL': '1'})
            self.assertEqual(output, '')

    def test_zsh_completion_and_options(self):
        self.run_shell('zsh', r'''
            [[ -o nomatch && ! -o shwordsplit ]] || exit 1
            [[ "$HISTSIZE:$SAVEHIST" = 50000:100000 ]] || exit 2
            [[ "${_comps[npm]}" = _npm_completion ]] || exit 3
            [[ -n "${_comps[git]}" ]] || exit 4
            [[ "$(bindkey '^A')" = *beginning-of-line* ]] || exit 5
        ''')

    def test_history_migration(self):
        data = self.home / '.local/share/atuin'
        data.mkdir(parents=True)
        (data / '.bash-imported').touch()
        script = ROOT / 'tools/migrate-history.bash'
        # An exported Bash function keeps real Atuin out of this test even
        # though the migration bootstraps Homebrew's PATH.
        code = f'''atuin() {{ "$HOME/.local/bin/atuin" "$@"; }}
export -f atuin
bash '{script}'
'''
        self.run_shell('bash', code, '-c')
        self.assertFalse((data / '.zsh-imported').exists())
        (self.home / '.zsh_history').write_text(': 1234567890:0;echo old\n')
        result = subprocess.run([SHELLS['bash'], '-c', code],
            env={**self.env, 'TEST_IMPORT_FAIL': 'zsh'}, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((data / '.zsh-imported').exists())
        self.run_shell('bash', code, '-c')
        self.assertTrue((data / '.zsh-imported').exists())
        calls = self.log.read_text()
        self.run_shell('bash', code, '-c')
        self.assertEqual(self.log.read_text(), calls)
        self.assertNotIn('atuin import bash', calls)


if __name__ == '__main__':
    unittest.main()
