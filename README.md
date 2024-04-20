# local-container.nvim

Inspired by vscode remote container.

lazy.nvim

```lua
{
  'goropikari/local-container.nvim',
  dependencies = {
    'ojroques/nvim-osc52'
  },
  opts = {
    neovim = {
      remote_port = 60002,
    }
  }
},
```

```bash
npm install -g @devcontainers/cli

sudo apt-get install -y socat
```




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
