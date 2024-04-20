![demo](./demo.gif)

```bash
git clone https://github.com/microsoft/vscode-remote-try-rust
cd vscode-remote-try-rust
devcontainer up --workspace-folder=. --additional-features='{"ghcr.io/goropikari/devcontainer-feature/socat:1": {},"ghcr.io/goropikari/devcontainer-feature/neovim:1": {}'
nvim
```

`:LCConnect`: start a neovim server in a container and forward ssh auth sock.


connect neovim server (copy following command to clipboard automatically by osc52)
```
nvim --remote-ui --server 172.17.0.2:60002
```
