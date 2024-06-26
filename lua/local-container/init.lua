local M = {}

local dc = require 'local-container.docker'
local settings = require 'local-container.settings'
local utils = require 'local-container.utils'

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
    print 'running container is not found.'
    return
  end
  vim.ui.select(
    names,
    { prompt = 'select container:' },
    function(name) callback(name) end
  )
end

function M.install_neovim()
  select_container(function(container_name)
    local _, err = utils.execute_cmd(
      string.format(
        "docker exec -u root %s %s",
        container_name,
        '/bin/bash -c "apt-get update && apt-get install -y curl && $(curl -fsSL https://raw.githubusercontent.com/goropikari/devcontainer-feature/main/src/neovim/install.sh)"'
      ),
      {}
    )
    if err then
      return err
    end
  end)
end

function M.install_socat()
  select_container(function(container_name)
    local _, err = utils.execute_cmd(
      string.format(
        "docker exec -u root %s %s",
        container_name,
        '/bin/bash -c "apt-get update && apt-get install -y curl && $(curl -fsSL https://raw.githubusercontent.com/goropikari/devcontainer-feature/main/src/socat/install.sh)"'
      ),
      {}
    )
    if err then
      return err
    end
  end)
end

function M.forward_ssh_sock_with_name(container_name)
  local config = settings.config
  local container_ssh_sock = config.ssh.container_ssh_sock
  local relay_port = config.ssh.relay_port
  local gateway, err = dc.fetch_container_gateway(container_name)
  if err then
    return err
  end

  -- make ssh_auth_sock in container
  _, err = utils.execute_cmd(
    string.format(
      "docker exec -u 1000 %s socat unix-listen:%s,fork tcp-connect:%s:%s &",
      container_name,
      container_ssh_sock,
      gateway,
      relay_port
    ), {})
  if err then
    return err
  end

  -- forward host ssh_auth_sock to container
  _, err = utils.execute_cmd(
    string.format(
      "socat %s tcp-listen:%s,fork &",
      os.getenv('SSH_AUTH_SOCK'),
      relay_port
    ),
    {}
  )
  if err then
    return err
  end
end

function M.forward_ssh_sock()
  select_container(function(container_name)
    local err = M.forward_ssh_sock_with_name(container_name)
    if err then
      return err
    end
  end)
end

local function _start_remote_neovim(container_name)
  local config = require('local-container.settings').config
  local _, err = utils.execute_cmd(
    string.format(
      'docker exec -u 1000 %s bash -c "SSH_AUTH_SOCK=%s %s --headless --listen 0.0.0.0:%s &"',
      container_name,
      config.ssh.container_ssh_sock,
      config.neovim.remote_path,
      config.neovim.remote_port
    ),
    { trim = true }
  )
  if err then
    return err
  end

  local container_ip_address
  container_ip_address, err = dc.fetch_container_ip_adderss(container_name)
  if err then
    return err
  end

  local neovim_cmd = string.format(
    'nvim --remote-ui --server %s:%s',
    container_ip_address,
    config.neovim.remote_port
  )
  require('osc52').copy(neovim_cmd)
  print(neovim_cmd)

  return false
end

function M.connect_container()
  select_container(function(name)
    M.forward_ssh_sock_with_name(name)
    _start_remote_neovim(name)
  end)
end

M.show_config = settings.show_config

return M
