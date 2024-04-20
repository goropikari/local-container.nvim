local M = {}

local utils = require 'local-container.utils'

function M.list_container_names()
  local cmd = 'docker ps --format {{.Names}}'
  local names, err = utils.execute_cmd(cmd, { trim = true })
  if err then
    return {}, err
  end
  return vim.split(names, '\n', { trimempty = true }), false
end

function M.fetch_container_hostname(container_name)
  local hostname, err = utils.execute_cmd('docker inspect ' .. container_name .. " --format='{{.Config.Hostname}}'", { trim = true })
  if err then
    print 'fetch hostname error'
    return '', err
  end

  return hostname, false
end

function M.fetch_container_gateway(container_name)
  local hostname, err = M.fetch_container_hostname(container_name)
  if err then
    return err
  end

  local gateway
  gateway, err = utils.execute_cmd('docker inspect ' .. hostname .. " --format='{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}'", { trim = true })
  if err then
    return err
  end

  return gateway, false
end

function M.fetch_container_ip_adderss(container_name)
  local hostname, err = M.fetch_container_hostname(container_name)
  if err then
    return '', err
  end

  local ip_address
  ip_address, err = utils.execute_cmd('docker inspect ' .. hostname .. " --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'", { trim = true })
  if err then
    print 'fetch ip address error'
    return '', err
  end

  return ip_address, false
end

return M
