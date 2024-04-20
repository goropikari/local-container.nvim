local M = {}

local utils = require('local-container.utils')
local dc = require('local-container.docker')

local config = {
	ssh = {
		container_ssh_sock = '/tmp/local_container_ssh_auth.sock',
		relay_port = 60000,
	},
	neovim = {
		remote_path = '/opt/nvim/squashfs-root/usr/bin/nvim',
		remote_port = 8888,
		local_port = 8888,
	},
	devcontainer = {
		path = 'devcontainer',
	},
}

function M.setup(opts)
end

local function forward_ssh_sock(container_name)
	local container_ssh_sock = config.ssh.container_ssh_sock
	local relay_port = config.ssh.relay_port
	local gateway, err = dc.fetch_container_gateway(container_name)
	if err then
		return err
	end

	-- make ssh_auth_sock in container
	_, err = utils.execute_cmd(
		'docker exec ' ..
		container_name ..
		' socat unix-listen:' .. container_ssh_sock .. ',fork tcp-connect:' .. gateway .. ':' .. relay_port .. ' &',
		{}
	)
	if err then
		return err
	end

	-- forward host ssh_auth_sock to container
	_, err = utils.execute_cmd(
		'socat ' .. os.getenv('SSH_AUTH_SOCK') .. ' tcp-listen:' .. relay_port .. ',fork &',
		{}
	)
	if err then
		return err
	end
end

local function start_remote_neovim(container_name)
	local nvim_cmd = 'docker exec ' ..
		container_name ..
		' bash -c "SSH_AUTH_SOCK=' ..
		config.ssh.container_ssh_sock ..
		' ' .. config.neovim.remote_path .. ' --headless --listen 0.0.0.0:' .. config.neovim.remote_port .. ' &"'

	local _, err = utils.execute_cmd(nvim_cmd, { trim = true })
	if err then
		return err
	end

	local container_ip_address
	container_ip_address, err = dc.fetch_container_ip_adderss(container_name)
	if err then
		return err
	end

	local socat_cmd = 'socat ' ..
		'tcp-listen:' .. config.neovim.local_port .. ',fork ' ..
		'tcp-connect:' .. container_ip_address .. ':' .. config.neovim.remote_port .. ' &'
	_, err = utils.execute_cmd(socat_cmd, {})
	if err then
		return err
	end
	local neovim_cmd = 'nvim --remote-ui --server localhost:' .. config.neovim.local_port
	require('osc52').copy(neovim_cmd)
	print(neovim_cmd)

	return false
end

local function select_container(callback)
	local names, err = dc.list_container_names()
	if err then
		return err
	end
	if names[1] == '' then
		print('running container is not found.')
		return
	end
	vim.ui.select(
		names,
		{ prompt = 'select container:' },
		function(name)
			callback(name)
		end
	)
end

function M.connect_container()
	select_container(
		function(name)
			forward_ssh_sock(name)
			start_remote_neovim(name)
		end
	)
end

return M
