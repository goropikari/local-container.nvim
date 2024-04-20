local M = {}

local cfg = require('local-container.settings').config

function M.devcontainer(op, args)
  args = args or ''
  if string.find(args, 'workspace%-folder') then
    print(vim.fn.system(cfg.devcontainer.path .. op .. ' ' .. args))
  else
    print(vim.fn.system(cfg.devcontainer.path .. ' ' .. op .. ' --workspace-folder=. ' .. args))
  end
end

function M.devcontainer_up(args)
  M.devcontainer('up', args)
end

return M
