```
lua require('local-container').connect_container()
```

```
vim.api.nvim_create_user_command(
	"ConnectContainer",
	require('local-container').connect_container,
	{}
)
```
