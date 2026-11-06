# blognew

## Publishing

`make publish` runs inside the container but needs your host git identity and
SSH credentials. Mount them read-only when launching `podman`:

```sh
podman run --rm \
    -v "$PWD:/site" \
    -v "$HOME/.gitconfig:/root/.gitconfig:ro" \
    -v "$HOME/.ssh:/root/.ssh:ro" \
    -e GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" \
    myblog make publish
```

- `~/.gitconfig` supplies the commit identity (`user.name`/`user.email`) and,
  if configured, `init.defaultBranch`.
- `~/.ssh` supplies your private key and `known_hosts` for the
  `git@github.com` push.
- `GIT_SSH_COMMAND` avoids an interactive host-key prompt when `known_hosts`
  isn't mounted.

### Gotchas

- SSH refuses loose private keys — ensure `chmod 600 ~/.ssh/id_*`.
- On SELinux hosts (Fedora/RHEL), append `:Z` to the `.ssh` mount or pass
  `--security-opt label=disable`.
