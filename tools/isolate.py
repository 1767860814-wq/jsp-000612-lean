#!/usr/bin/env python3
"""Linux helper: execute a command unprivileged with resource/network restrictions.

Requires libseccomp. Fails closed if restrictions cannot be installed. This is
process-level isolation, not a VM or filesystem sandbox. It is not an independent
Lean checker. No external Python packages are required.
"""
from __future__ import annotations
import argparse
import ctypes
import ctypes.util
import errno
import os
import resource
import socket
import sys
from pathlib import Path


def restrict_network() -> None:
    name = ctypes.util.find_library('seccomp')
    if not name:
        raise RuntimeError('libseccomp is required; refusing an unrestricted run')
    sc = ctypes.CDLL(name, use_errno=True)
    sc.seccomp_init.argtypes = [ctypes.c_uint32]
    sc.seccomp_init.restype = ctypes.c_void_p
    sc.seccomp_release.argtypes = [ctypes.c_void_p]
    sc.seccomp_syscall_resolve_name.argtypes = [ctypes.c_char_p]
    sc.seccomp_syscall_resolve_name.restype = ctypes.c_int
    sc.seccomp_rule_add.argtypes = [ctypes.c_void_p, ctypes.c_uint32, ctypes.c_int, ctypes.c_uint]
    sc.seccomp_rule_add.restype = ctypes.c_int
    sc.seccomp_load.argtypes = [ctypes.c_void_p]
    sc.seccomp_load.restype = ctypes.c_int
    ctx = sc.seccomp_init(0x7FFF0000)  # SCMP_ACT_ALLOW
    if not ctx:
        raise RuntimeError('seccomp_init failed')
    denied = []
    try:
        for syscall in ['socket', 'socketpair', 'connect', 'accept', 'accept4', 'bind',
                        'listen', 'sendto', 'sendmsg', 'sendmmsg', 'recvfrom', 'recvmsg',
                        'recvmmsg', 'shutdown', 'getsockname', 'getpeername',
                        'setsockopt', 'getsockopt', 'socketcall']:
            number = sc.seccomp_syscall_resolve_name(syscall.encode())
            if number < 0:
                continue  # E.g. multiplexed socketcall is absent on x86_64.
            rc = sc.seccomp_rule_add(ctx, 0x00050000 | errno.EPERM, number, 0)
            if rc != 0:
                raise RuntimeError(f'seccomp_rule_add({syscall}) failed: {rc}')
            denied.append(syscall)
        if sc.seccomp_load(ctx) != 0:
            raise RuntimeError('seccomp_load failed')
    finally:
        sc.seccomp_release(ctx)
    print('NETWORK_SYSCALLS_DENIED: ' + ','.join(denied), flush=True)
    try:
        probe = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    except OSError as exc:
        if exc.errno != errno.EPERM:
            raise RuntimeError(f'Unexpected network probe errno: {exc.errno}') from exc
        print('NETWORK_DENIAL_PROBE: PASS (EPERM)', flush=True)
    else:
        probe.close()
        raise RuntimeError('Network-denial probe unexpectedly succeeded')


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--uid', type=int)
    p.add_argument('--gid', type=int)
    p.add_argument('--cpu-seconds', type=int, default=180)
    p.add_argument('--memory-mib', type=int, default=8192)
    p.add_argument('--cwd', type=Path)
    p.add_argument('command', nargs=argparse.REMAINDER)
    a = p.parse_args()
    cmd = a.command[1:] if a.command[:1] == ['--'] else a.command
    if not cmd:
        p.error('A command is required after --')
    if sys.platform != 'linux':
        p.error('This isolation helper supports Linux only')
    if a.cpu_seconds <= 0 or a.memory_mib <= 0:
        p.error('Resource limits must be positive')
    if os.geteuid() == 0:
        if a.uid is None or a.uid <= 0:
            p.error('When invoked as root, explicitly supply a nonzero --uid')
        os.setgroups([])
        os.setgid(a.gid if a.gid is not None else a.uid)
        os.setuid(a.uid)
    elif a.uid is not None and a.uid != os.geteuid():
        p.error('Cannot switch to a different UID without root')
    if os.geteuid() == 0:
        raise RuntimeError('Refusing to execute as root')
    if a.cwd:
        os.chdir(a.cwd)
    resource.setrlimit(resource.RLIMIT_CPU, (a.cpu_seconds, a.cpu_seconds))
    memory = a.memory_mib * 1024**2
    resource.setrlimit(resource.RLIMIT_AS, (memory, memory))
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    libc = ctypes.CDLL(None, use_errno=True)
    if libc.prctl(38, 1, 0, 0, 0) != 0:  # PR_SET_NO_NEW_PRIVS
        raise OSError(ctypes.get_errno(), 'prctl(PR_SET_NO_NEW_PRIVS)')
    print(f'ISOLATED_UID: {os.geteuid()}', flush=True)
    print(f'ISOLATED_GID: {os.getegid()}', flush=True)
    print(f'CPU_LIMIT_SECONDS: {a.cpu_seconds}', flush=True)
    print(f'VIRTUAL_MEMORY_LIMIT_MIB: {a.memory_mib}', flush=True)
    print('NO_NEW_PRIVILEGES: true', flush=True)
    restrict_network()
    print('COMMAND: ' + repr(cmd), flush=True)
    os.execvpe(cmd[0], cmd, dict(os.environ))

if __name__ == '__main__':
    main()
