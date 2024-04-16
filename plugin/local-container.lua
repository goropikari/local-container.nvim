if vim.g.loaded_neovim_local_container == 1 then
	return
end
vim.g.loaded_neovim_local_container = 1

vim.api.nvim_create_user_command(
	"ConnectContainer",
	function()
		local result = vim.split(vim.fn.system('docker ps --format {{.Names}}'):sub(1, -2), "\n")
		local container_id = ""
		vim.ui.select(result, {
			prompt = 'Select tabs or spaces:',
			format_item = function(item)
				return item
			end,
		}, function(choice)
			container_id = vim.fn.system('docker ps -f name=^' .. choice .. '$ -q'):sub(1, -1)
			print(container_id)
		end)
	end, {}
)
