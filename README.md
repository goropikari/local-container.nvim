```lua
lua require('local-container').connect_container()
```

```lua
vim.api.nvim_create_user_command(
	"ConnectContainer",
	require('local-container').connect_container,
	{}
)
```
