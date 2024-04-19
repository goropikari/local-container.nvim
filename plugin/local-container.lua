if vim.g.loaded_neovim_local_container == 1 then
	return
end
vim.g.loaded_neovim_local_container = 1

vim.api.nvim_create_user_command(
	"ConnectContainer",
	require('local-container').connect_container,
	{}
)
