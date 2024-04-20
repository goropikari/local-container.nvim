local M = {}

local DEFAULT_CONFIG = {
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
}

function M._define_command()
	vim.api.nvim_create_user_command(
		"LCConnect",
		require('local-container').connect_container,
		{}
	)
end

function M._update_setting(opts)
	M.config = DEFAULT_CONFIG
	for key, value in pairs(DEFAULT_CONFIG) do
		local v2 = opts[key]
		if v2 then
			M.config[key] = vim.fn.extend(value, v2)
		end
	end
end

return M
