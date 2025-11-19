--- line-mover.nvim
--- Features:
---   * Move the current line (Normal mode) or visual selection (Visual/Block mode) up or down.
---   * Horizontally indent/unindent the current line (Normal mode) or visual selection (Visual/Block mode).
---   * Supports repetition using the Vim count prefix (e.g., `5<A-k>` moves 5 lines up).
---
---
--- Configuration:
--- ```lua
--- require('line-mover').setup({
---     mappings = {
---         -- Normal Mode Mappings (for single line movement/indentation)
---         one_up = "<A-k>",
---         one_down = "<A-j>",
---         one_left = "<A-h>",
---         one_right = "<A-l>",
---
---         -- Visual Mode Mappings (for selection movement/indentation)
---         visual_up = "<A-k>",
---         visual_down = "<A-j>",
---         visual_left = "<A-h>",
---         visual_right = "<A-l>",
---     },
---     -- Add other configuration options here in the future
--- })
--- ```
---
--- Default Mappings:
--- The plugin defaults to using the **Alt** key combined with standard motion keys:
---
--- * **Vertical Movement (Line/Selection)**
---     * `<Alt-k>`: Move **Up**
---     * `<Alt-j>`: Move **Down**
---
--- * **Horizontal Movement (Line/Selection)**
---     * `<Alt-h>`: Move **Left** (Un-indent)
---     * `<Alt-l>`: Move **Right** (Indent)
---

---@alias _move_direction string: One of "left", "down", "up", "right".

-- Module definition ==========================================================
local Module = {} -- Module logic
local H = {} -- Helper functions
H.move_keys = {}
local default_config = {
	mappings = {
		one_up = "<A-k>",
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
	H.check_type("user_config", config, "table", true)
	_G.LineMover = Module
	config = vim.tbl_deep_extend("force", default_config, config or {})

	H.check_type("mappings", config.mappings, "table")
	H.check_type("mappings.one_up", config.mappings.one_up, "string")
	H.check_type("mappings.one_down", config.mappings.one_down, "string")
	H.check_type("mappings.one_left", config.mappings.one_left, "string")
	H.check_type("mappings.one_right", config.mappings.one_right, "string")

	H.check_type("mappings.visual_up", config.mappings.visual_up, "string")
	H.check_type("mappings.visual_down", config.mappings.visual_down, "string")
	H.check_type("mappings.visual_left", config.mappings.visual_left, "string")
	H.check_type("mappings.visual_right", config.mappings.visual_right, "string")

	H.check_type("options", config.options, "table", true)

	-- stylua: ignore start
	H.map( "n", default_config.mappings.one_down,  "<Cmd>lua LineMover.move_line('down')<CR>", { desc = "Move one line down" })
	H.map( "n", default_config.mappings.one_left,  "<Cmd>lua LineMover.move_line('left')<CR>", { desc = "Move one line left" })
	H.map( "n", default_config.mappings.one_right, "<Cmd>lua LineMover.move_line('right')<CR>",{ desc = "Move one line right" })
	H.map( "n", default_config.mappings.one_up,    "<Cmd>lua LineMover.move_line('up')<CR>",   { desc = "Move one line up" })

	H.map( "x", default_config.mappings.visual_down,  "<Cmd>lua LineMover.move_selection('down')<CR>",  { desc = "Move visual selection down" })
	H.map( "x", default_config.mappings.visual_up,    "<Cmd>lua LineMover.move_selection('up')<CR>",    { desc = "Move visual selection up" })
	H.map( "x", default_config.mappings.visual_left,  "<Cmd>lua LineMover.move_selection('left')<CR>",  { desc = "Move visual selection left" })
	H.map( "x", default_config.mappings.visual_right, "<Cmd>lua LineMover.move_selection('right')<CR>", { desc = "Move visual selection right" })
	-- stylua: ignore end
end

Module.move_line = function(_move_direction)
	-- Get cursor position, position of end_char
	local ref_curpos, ref_last_col = vim.fn.getcurpos(), vim.fn.col("$")
	if ref_curpos[2] == 1 and _move_direction == "up" then
		return
	end

	local repeat_times = vim.v.count1

	-- First handle horizontal movements
	if _move_direction == "left" or _move_direction == "right" then
		local key = H.indent_keys[_move_direction]
		vim.cmd(string.rep(key, repeat_times)) --
		H.correct_cursor_col(ref_curpos, ref_last_col)
		return
	end

	local cache_z_reg = vim.fn.getreginfo("z") -- save caching register

	vim.cmd('normal! "zyy"_dd') -- Yank to "z register current line, remove it to black hole reg

	local paste_key = _move_direction == "down" and "p" or "P"
	repeat_times = _move_direction == "down" and repeat_times - 1 or repeat_times
	if repeat_times > 0 then
		-- move current line repeat_times times
		vim.cmd("normal!" .. string.rep(H.move_keys[_move_direction], repeat_times))
	end

	vim.cmd('normal! "z' .. paste_key) -- Paste from "z register before/after current line
	vim.cmd("normal! ==") -- align moved line

	H.correct_cursor_col(ref_curpos, ref_last_col)

	-- Restore starting values for register
	vim.fn.setreg('"z', cache_z_reg)
end

Module.move_selection = function(_move_direction)
	-- Act only inside visual mode
	if not (vim.fn.mode() == "v" or vim.fn.mode() == "V" or vim.fn.mode() == "\22") then
		return
	end

	local ref_curpos, ref_last_col = vim.fn.getcurpos(), vim.fn.col("$")
	if ref_curpos[2] == 1 and _move_direction == "up" then
		return
	end

	local repeat_times = vim.v.count1

	-- First handle horizontal movements
	if _move_direction == "left" or _move_direction == "right" then
		local key = H.indent_keys[_move_direction]
		vim.cmd("normal! " .. string.rep(key .. "gv", repeat_times)) --
		H.correct_cursor_col(ref_curpos, ref_last_col)
		return
	end

	local cache_z_reg = vim.fn.getreginfo("z") -- save caching register

	vim.cmd('normal! "zygv"_d') -- Yank to "z register current line, remove it to black hole reg

	local paste_key = _move_direction == "down" and "p" or "P"
	repeat_times = _move_direction == "down" and repeat_times - 1 or repeat_times
	if repeat_times > 0 then
		-- move current line repeat_times times
		vim.cmd("normal!" .. string.rep(H.move_keys[_move_direction], repeat_times))
	end

	vim.cmd('normal! "z' .. paste_key) -- Paste from "z register before/after current line
	vim.cmd("normal! `[1v=gv") -- align moved line

	H.correct_cursor_col(ref_curpos, ref_last_col)

	-- Restore starting values for register
	vim.fn.setreg('"z', cache_z_reg)
end

-- Helpers
H.move_keys = { left = "h", down = "j", up = "k", right = "l" }
H.indent_keys = { left = "<", right = ">" }
H.print_error = function(msg)
	error("(line-mover.nvim) " .. msg)
end

H.check_type = function(name, val, expected, allow_nil)
	if (type(val) == expected) or (allow_nil == true and val == nil) then
		return
	end
	H.print_error(name .. " should be type of " .. expected .. ", not " .. type(val))
end

H.map = function(mode, lhs, rhs, opts)
	opts = vim.tbl_deep_extend("force", { silent = true }, opts)
	vim.keymap.set(mode, lhs, rhs, opts)
end

H.correct_cursor_col = function(ref_curpos, ref_last_col)
	local col_diff = vim.fn.col("$") - ref_last_col
	local new_col = math.max(ref_curpos[3] + col_diff, 1)

	vim.fn.cursor({ vim.fn.line("."), new_col })
end

Module.setup()

return Module
