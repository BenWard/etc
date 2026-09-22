#!/usr/bin/env python3
"""Exercise installed integrations in PTYs without touching personal history."""
import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import tomllib

ROOT = Path(__file__).resolve().parents[1]


def check_installed():
    """Check deployed startup files with the user's existing environment."""
    for shell in ('bash', 'zsh'):
        for flags in ('-ic', '-lic'):
            code = r'''
                type hist nr pr wt github dcrun >/dev/null || exit 10
                command -v node >/dev/null || exit 11
                before=$PATH
                resource
                resource
                [[ "$before" = "$PATH" ]] || exit 12
                printf 'ok: installed %s startup and reload\n' "$DOTFILES_SHELL"
            '''
            result = subprocess.run([shutil.which(shell), flags, code],
                capture_output=True, text=True, timeout=30)
            errors = [line for line in result.stderr.splitlines()
                      if 'cannot set terminal process group' not in line
                      and 'no job control in this shell' not in line]
            assert result.returncode == 0 and not errors, result.stdout + result.stderr
            print(result.stdout.strip(), flags)
    for flags in ('-c', '-lc'):
        result = subprocess.run([shutil.which('zsh'), flags,
            'command -v node >/dev/null && printf quiet'],
            capture_output=True, text=True, timeout=30)
        assert result.returncode == 0 and result.stdout == 'quiet' and not result.stderr, result
    print('ok: installed non-interactive zsh finds node without startup output')


class Terminal:
    def __init__(self, executable, env, cwd):
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.chdir(cwd)
            os.execve(executable, [executable, '-il'], env)
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 140, 0, 0))
        self.output = b''

    def send(self, text):
        os.write(self.fd, text.encode())

    def expect(self, marker, timeout=30):
        deadline = time.monotonic() + timeout
        while marker.encode() not in self.output:
            if time.monotonic() >= deadline:
                raise AssertionError(f'Missing {marker!r}:\n{self.output.decode(errors="replace")}')
            if select.select([self.fd], [], [], 0.1)[0]:
                try:
                    data = os.read(self.fd, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    data = b''
                if not data:
                    raise AssertionError(self.output.decode(errors='replace'))
                self.output += data
        before, self.output = self.output.split(marker.encode(), 1)
        return before.decode(errors='replace')

    def close(self):
        self.send('\x03exit\n')
        deadline = time.monotonic() + 3
        try:
            while time.monotonic() < deadline:
                if os.waitpid(self.pid, os.WNOHANG)[0]:
                    return
                if select.select([self.fd], [], [], 0.1)[0]:
                    try:
                        os.read(self.fd, 65536)
                    except OSError:
                        break
            # Interactive shells may ignore SIGTERM; never block teardown.
            if not os.waitpid(self.pid, os.WNOHANG)[0]:
                os.kill(self.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        finally:
            os.close(self.fd)


def main():
    for shell in ('bash', 'zsh'):
        with tempfile.TemporaryDirectory(prefix=f'dotfiles-live-{shell}-') as folder:
            home = Path(folder)
            shutil.copytree(ROOT / 'home/dot_dotfiles_lib', home / '.dotfiles_lib')
            for name in ('bashrc', 'bash_profile', 'zshenv', 'zprofile', 'zshrc'):
                shutil.copyfile(ROOT / f'home/dot_{name}', home / f'.{name}')
            config = home / '.config'
            (config / 'atuin').mkdir(parents=True)
            (config / 'atuin/config.toml').write_text(
                'auto_sync = false\nupdate_check = false\nenter_accept = true\n[daemon]\nenabled = false\n'
            )
            # Render the same prompt template, using its default semantic color.
            prompt = (ROOT / 'home/dot_config/starship.toml.tmpl').read_text()
            defaults = tomllib.loads((ROOT / 'home/.chezmoidata.toml').read_text())
            (config / 'starship.toml').write_text(prompt.replace('{{ .userHostColor }}', defaults['userHostColor']))
            env = {
                'HOME': str(home), 'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
                'TERM': 'xterm-256color', 'USER': os.environ.get('USER', 'test'),
                'SHELL': '/wrong/shell', 'LC_ALL': 'en_US.UTF-8',
                'BASH_SILENCE_DEPRECATION_WARNING': '1',
                # Reuse installed runtimes, but read config only from the temp home.
                'MISE_DATA_DIR': str(Path.home() / '.local/share/mise'),
            }
            terminal = Terminal(shutil.which(shell), env, home)
            try:
                terminal.send("printf '\\n__READY__\\n'\n")
                startup = terminal.expect('\r\n__READY__\r\n')
                for error in ('command not found', 'Traceback', 'parse error', 'syntax error'):
                    assert error not in startup, startup
                # An actual prompt renders the configured clock before commands.
                assert '[' in startup and '~' in startup, startup
                if shell == 'zsh':
                    check = '''before=$PATH; hooks_before="${precmd_functions[*]}|${preexec_functions[*]}"; resource; resource; [[ "$before" = "$PATH" && "$hooks_before" = "${precmd_functions[*]}|${preexec_functions[*]}" && -n "${_comps[git]}" && -n "${_comps[npm]}" ]] && printf '\\n__CHECKED__\\n' '''
                else:
                    check = '''before=$PATH; hooks_before="${PROMPT_COMMAND[*]}|${precmd_functions[*]}|${preexec_functions[*]}"; resource; resource; [[ "$before" = "$PATH" && "$hooks_before" = "${PROMPT_COMMAND[*]}|${precmd_functions[*]}|${preexec_functions[*]}" ]] && complete -p npm >/dev/null && printf '\\n__CHECKED__\\n' '''
                terminal.send(check + '\n')
                terminal.expect('\r\n__CHECKED__\r\n')
                # Native line editors must offer a command without executing it.
                terminal.send("_dotfiles_hist_edit 'touch selected-command-ran'\n")
                terminal.expect('selected-command-ran')
                # Allow the next prompt/readline invocation to appear, then cancel.
                time.sleep(0.3)
                assert not (home / 'selected-command-ran').exists()
                terminal.send('\x03')
                terminal.send("printf '\\n__CANCELLED__\\n'\n")
                terminal.expect('\r\n__CANCELLED__\r\n')
                assert not (home / 'selected-command-ran').exists()
                terminal.send("_dotfiles_hist_edit 'touch selected-command-ran'\n")
                terminal.expect('selected-command-ran')
                time.sleep(0.3)
                terminal.send('\x01\x0btouch edited-command-ran\n')
                terminal.send("printf '\\n__EDITED__\\n'\n")
                terminal.expect('\r\n__EDITED__\r\n')
                assert (home / 'edited-command-ran').exists()
                assert not (home / 'selected-command-ran').exists()
                # Complete a pathname containing spaces through the real editor.
                (home / 'unique completion target').touch()
                terminal.send('printf "<%s>\\n" unique\t\n')
                terminal.expect('<unique completion target>\r\n')
                print(f'ok: {shell} prompt, hooks/reload, history cancellation, and Tab completion')
            finally:
                terminal.close()


if __name__ == '__main__':
    if sys.argv[1:] == ['--installed']:
        check_installed()
    else:
        main()
