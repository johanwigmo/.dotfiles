vim.g.mapleader = " ";
vim.g.maplocalleader = " "

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

local function split_or_herdr(key)
	local directions = { h = "left", j = "down", k = "up", l = "right" }
	return function()
		if vim.api.nvim_get_mode().mode == "t" then
			vim.cmd.stopinsert()
		end
		local before = vim.api.nvim_get_current_win()
		vim.cmd.wincmd(key)
		if vim.api.nvim_get_current_win() == before and vim.env.HERDR_PANE_ID then
			vim.system({ "herdr", "pane", "focus", "--direction", directions[key], "--current" })
		end
	end
end

for _, key in ipairs({ "h", "j", "k", "l" }) do
	vim.keymap.set({ "n", "t" }, "<C-" .. key .. ">", split_or_herdr(key))
end
