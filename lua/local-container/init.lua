local M = {}

local config = {
	container_ssh_sock = '/tmp/local_container_ssh_auth.sock',
	ssh_relay_port = 60000,
	neovim_remote_port = 8888,
	neovim_local_port = 8888,
}

function M.devcontainer(op, args)
	local devcontainer_path = 'devcontainer'
	-- vim.fn.system('devcontainer ' .. op .. ' ' .. args)
	vim.fn.system(devcontainer_path .. ' ' .. op .. ' --workspace-folder . ' .. args)
end

local function list_container_names()
	return vim.split(vim.fn.system('docker ps --format {{.Names}}'):sub(1, -2), "\n")
end

local function forward_ssh_sock(container_name)
	local container_ssh_sock = config.container_ssh_sock
	local relay_port = config.ssh_relay_port
	local gateway = vim.fn.system(
		'docker inspect ' .. container_name .. " --format='{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}'"
	):sub(1, -2)
	-- make ssh_auth_sock in container
	vim.fn.system(
		'docker exec ' ..
		container_name ..
		' socat unix-listen:' .. container_ssh_sock .. ',fork tcp-connect:' .. gateway .. ':' .. relay_port .. ' &'
	)
	-- forward host ssh_auth_sock to container
	vim.fn.system('socat ' .. os.getenv('SSH_AUTH_SOCK') .. ' tcp-listen:' .. relay_port .. ',fork &')
end

local function start_remote_neovim(container_name)
	vim.fn.system('docker exec ' ..
		container_name ..
		' bash -c "SSH_AUTH_SOCK=' ..
		config.container_ssh_sock .. ' nvim --headless --listen 0.0.0.0:' .. config.neovim_remote_port .. ' &"')

	local container_ip_address =
		vim.fn.system(
			'docker inspect ' .. container_name .. " --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"
		):sub(1, -2)
	local socat_cmd = 'socat ' ..
		'tcp-listen:' .. config.neovim_local_port .. ',fork ' ..
		'tcp-connect:' .. container_ip_address .. ':' .. config.neovim_remote_port .. ' &'
	vim.fn.system(socat_cmd)
	local neovim_cmd = 'nvim --remote-ui --server localhost:' .. config.neovim_local_port
	require('osc52').copy(neovim_cmd)
	print(neovim_cmd)
end

function M.connect_container()
	local names = list_container_names()
	if names[1] == '' then
		print('running container is not found.')
		return
	end
	vim.ui.select(
		names,
		{ prompt = 'select container:' },
		function(name)
			forward_ssh_sock(name)
			start_remote_neovim(name)
		end
	)
end

return M
