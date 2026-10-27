# debian001 – Debian VM + signed apt repo

VM: WSL2 distro `debian001` (stable), disk in `C:\source\debian001\vm`.
Repo: reprepro, signed, served by nginx inside the VM on port 8080.

## Use
0. Login is root by default (no user account to create): `wsl -d debian001` or `wsl -d debian001 -u root`
1. Drop `.deb` files in `C:\source\debian001\repo\incoming`
2. Publish:  `wsl -d debian001 -u root repo-upload`
3. Install:  `wsl -d debian001 -u root`, then `apt-get update && apt-get install <pkg>`

The VM's apt is already configured (`/etc/apt/sources.list.d/debian001.list`).
Other machines: fetch `http://<host>:8080/debian001.asc`, then
`deb [signed-by=/usr/share/keyrings/debian001.gpg] http://<host>:8080 stable main`
(`gpg --dearmor` the .asc, or use /debian001.gpg directly).

Remove a package: `wsl -d debian001 -u root reprepro -b /srv/repo remove stable <pkg>`
Re-provision from scratch: `wsl -d debian001 -u root bash /mnt/c/source/debian001/repo/provision.sh`
Delete VM entirely: `wsl --unregister debian001`

## Memory (vmmemWSL)
All WSL distros (Ubuntu, debian001, Docker Desktop) share one VM, and by default
it keeps file cache indefinitely, so `vmmemWSL` can grow to many GB. Limit it with
`C:\Users\<you>\.wslconfig`:

```
[wsl2]
memory=6GB

[experimental]
autoMemoryReclaim=gradual
```

Apply with `wsl --shutdown` (stops all distros and Docker containers).
Raise `memory` if containers get OOM-killed.
