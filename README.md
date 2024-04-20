# local-container.nvim

Inspired by vscode remote container.


# Instalation

With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'goropikari/local-container.nvim',
  dependencies = {
    'ojroques/nvim-osc52'
  },
}
```

```bash
npm install -g @devcontainers/cli

sudo apt-get install -y socat
```


# Setup

```lua
require('local-container').setup({
	ssh = {
		container_ssh_sock = '/tmp/local_container_ssh_auth.sock',
		relay_port = 60000,
	},
	neovim = {
		remote_path = '/opt/nvim/squashfs-root/usr/bin/nvim',
		remote_port = 60001,
	},
	devcontainer = {
		path = 'devcontainer',
	},
})
```

# Usage

```lua
lua require('local-container').connect_container()
```

```lua
vim.api.nvim_create_user_command(
	"LCConnect",
	require('local-container').connect_container,
	{}
)
```
