local M = {}

function M.shell_error()
	return vim.v.shell_error ~= 0
end

function M.execute_cmd(cmd, opts)
	local result
	if opts.trim then
		result = vim.trim(vim.fn.system(cmd))
	else
		result = vim.fn.system(cmd)
	end
	return result, M.shell_error()
end

return M
