local M = {}

local settings = require('local-container.settings')
local utils = require('local-container.utils')
local dc = require('local-container.docker')

function M.setup(opts)
	settings._update_setting(opts)
	settings._define_command()
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

function M.install_neovim()
	select_container(
		function(container_name)
			local _, err = utils.execute_cmd('docker exec -u root ' ..
				container_name ..
				' /bin/bash -c "apt-get update && apt-get install -y curl && $(curl -fsSL https://raw.githubusercontent.com/goropikari/devcontainer-feature/main/src/neovim/install.sh)"',
				{}
			)
			if err then
				return err
			end
		end
	)
end

function M.install_socat()
	select_container(function(container_name)
		local _, err = utils.execute_cmd(
			'docker exec -u root ' ..
			container_name ..
			' /bin/bash -c "apt-get update && apt-get install -y curl && $(curl -fsSL https://raw.githubusercontent.com/goropikari/devcontainer-feature/main/src/socat/install.sh)"',
			{}
		)
		if err then
			return err
		end
	end)
end

local function forward_ssh_sock(container_name)
	local config = settings.config
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
	local config = require('local-container.settings').config
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

	local neovim_cmd = 'nvim --remote-ui --server ' .. container_ip_address .. ':' .. config.neovim.remote_port
	require('osc52').copy(neovim_cmd)
	print(neovim_cmd)

	return false
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
