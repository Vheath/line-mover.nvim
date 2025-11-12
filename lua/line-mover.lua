--- line-mover.nvim

--- MIT License Copyright (c) 2025 Timur Gruzdev
--- Features:

---@alias _move_direction string: One of "left", "down", "up", "right".

-- Module definition ==========================================================
local Module = {} -- Module logic
local Helpers = {} -- Helper functions
Helpers.move_keys = {}
local default_config = {
	mappings = {
		one_up = "<a-k>",
		one_down = "<A-j>",
		one_left = "<A-h>",
		one_right = "<A-l>",
		visual_up = "<A-k>",
		visual_down = "<A-j>",
		visual_left = "<A-h>",
		visual_right = "<A-l>",
	},
}

-- Setup function
Module.setup = function(config)
	Helpers.check_type("user_config", config, "table", true)
	_G.LineMover = Module
	config = vim.tbl_deep_extend("force", default_config, config or {})

	Helpers.check_type("mappings", config.mappings, "table")
	Helpers.check_type("mappings.one_up", config.mappings.one_up, "string")
	Helpers.check_type("mappings.one_down", config.mappings.one_down, "string")
	Helpers.check_type("mappings.one_left", config.mappings.one_left, "string")
	Helpers.check_type("mappings.one_right", config.mappings.one_right, "string")

	Helpers.check_type("mappings.visual_up", config.mappings.visual_up, "string")
	Helpers.check_type("mappings.visual_down", config.mappings.visual_down, "string")
	Helpers.check_type("mappings.visual_left", config.mappings.visual_left, "string")
	Helpers.check_type("mappings.visual_right", config.mappings.visual_right, "string")

	Helpers.check_type("options", config.options, "table", true)

	Helpers.map(
		"n",
		default_config.mappings.one_down,
		"<Cmd>lua LineMover.move_line('down')<CR>",
		{ desc = "Move one line down" }
	)
	Helpers.map(
		"n",
		default_config.mappings.one_left,
		"<Cmd>lua LineMover.move_line('left')<CR>",
		{ desc = "Move one line left" }
	)
	Helpers.map(
		"n",
		default_config.mappings.one_right,
		"<Cmd>lua LineMover.move_line('right')<CR>",
		{ desc = "Move one line right" }
	)
	Helpers.map(
		"n",
		default_config.mappings.one_up,
		"<Cmd>lua LineMover.move_line('up')<CR>",
		{ desc = "Move one line up" }
	)

	-- 1. Normal Mode: Move Current Line Up/Down
	-- :m .-2 moves the current line to BEFORE the current line (.-1),
	-- effectively shifting it up.
	-- vim.keymap.set("n", "<A-k>", ":m .-2<CR>", opts)

	-- :m .+1 moves the current line to AFTER the current line (which is .+0),
	-- effectively shifting it down.
	-- vim.keymap.set("n", "<A-j>", ":m .+1<CR>", opts)

	-- 2. Visual Mode (Linewise, Blockwise, or Charwise): Move Selection Up/Down
	-- 'x' map mode covers Visual, Visual-Line, and Visual-Block modes.

	-- Move UP:
	-- :m '<-2<CR>  -> Move selection (defined by '<,'>) to before the start of the selection.
	-- gv=gv       -> Re-select the moved block, auto-indent, and re-select again.
	-- vim.keymap.set("x", "<A-k>", ":m '<-2<CR>gv=gv", opts)

	-- Move DOWN:
	-- :m '>+1<CR>  -> Move selection to after the end of the selection.
	-- gv=gv       -> Re-select the moved block, auto-indent, and re-select again.
	-- vim.keymap.set("x", "<A-j>", ":m '>+1<CR>gv=gv", opts)
end

Module.move_line = function(_move_direction)
	local ref_curpos, ref_last_col = vim.fn.getcurpos(), vim.fn.col("$")

	-- Allow undo of consecutive moves at once (direction doesn't matter)
	if _move_direction == "left" or _move_direction == "right" then
		local key = Helpers.indent_keys[_move_direction]
		vim.cmd(string.rep(key, 1))
		Helpers.correct_cursor_col(ref_curpos, ref_last_col)
		return
	end
	-- save caching register
	local cache_z_reg = vim.fn.getreginfo("z")

	vim.api.nvim_feedkeys('"zyy"_dd', "n", false) -- Yank to "z register current line, remove it to black hole reg
	if _move_direction == "down" then
		-- vim.api.nvim_feedkeys(Helpers.move_keys[_move_direction], "n", false) -- move down
		vim.api.nvim_feedkeys('"zp', "n", false) -- Paste from "z register after current line
	else
		vim.api.nvim_feedkeys('"zP', "n", false) -- Paste from "z register before current line

		Helpers.correct_cursor_col(ref_curpos, ref_last_col)

		-- Restore starting values for register
		vim.fn.setreg('"z', cache_z_reg)
	end
end

-- Helpers
Helpers.move_keys = { left = "h", down = "j", up = "k", right = "l" }
Helpers.indent_keys = { left = "<", right = ">" }
Helpers.print_error = function(msg)
	error("(line-mover.nvim) " .. msg)
end

Helpers.check_type = function(name, val, expected, allow_nil)
	if (type(val) == expected) or (allow_nil == true and val == nil) then
		return
	end
	Helpers.print_error(name .. " should be type of " .. expected .. ", not " .. type(val))
end

Helpers.map = function(mode, lhs, rhs, opts)
	opts = vim.tbl_deep_extend("force", { silent = true }, opts)
	vim.keymap.set(mode, lhs, rhs, opts)
end

Helpers.correct_cursor_col = function(ref_curpos, ref_last_col)
	local col_diff = vim.fn.col("$") - ref_last_col
	local new_col = math.max(ref_curpos[3] + col_diff, 1)

	vim.fn.cursor({ vim.fn.line("."), new_col, ref_curpos[4], ref_curpos[5] + col_diff })
end

Helpers.make_cmd_normal = function(include_undojoin)
	local normal_command = (include_undojoin and "undojoin | " or "") .. "silent keepjumps normal! "

	return function(x)
		-- Caching and restoring data on every command is not necessary but leads
		-- to a nicer implementation

		-- Disable 'mini.bracketed' to avoid unwanted entries to its yank history
		local cache_minibracketed_disable = vim.b.minibracketed_disable
		local cache_unnamed_register = { points_to = vim.fn.getreginfo('"').points_to }

		-- Don't track possible put commands into yank history
		vim.b.minibracketed_disable = true

		vim.cmd(normal_command .. x)

		vim.b.minibracketed_disable = cache_minibracketed_disable
		vim.fn.setreg('"', cache_unnamed_register)
	end
end

Module.setup()

return Module
