# line-mover.nvim
## Introduction                                          
LineMover is a lightweight Neovim plugin that provides seamless, repeatable
movement of the current line or a visual selection both vertically (up/down)
and horizontally (indent/unindent).
## Installation                                         
Use your preferred package manager (e.g., packer.nvim, lazy.nvim).

Example (lazy.nvim):
```lua
{
    'Vheath/line-mover.nvim',
    config = function()
      require('line-mover').setup()
    end,
},
```


## Configuration
The plugin is configured by calling the `setup()` function. All
mappings are defined under the `mappings` key.
```lua
  require('line-mover').setup({
      mappings = {
          -- Default Mappings:
          one_up     = '<A-k>',    -- Normal Mode: Move line up
          one_down   = '<A-j>',    -- Normal Mode: Move line down
          one_left   = '<A-h>',    -- Normal Mode: Indent line left
          one_right  = '<A-l>',    -- Normal Mode: Indent line right

          visual_up    = '<A-k>',  -- Visual Mode: Move selection up
          visual_down  = '<A-j>',  -- Visual Mode: Move selection down
          visual_left  = '<A-h>',  -- Visual Mode: Indent selection left
          visual_right = '<A-l>',  -- Visual Mode: Indent selection right
      },
  })
  ```

## Usage
The main and only feature is moving lines and selections both
vertically/horizontally.

### Moving Lines in Normal Mode                           
The following commands move the current line (defaults):
- `<A-k>`    Move current line **up** 
- `<A-j>`    Move current line **down** 
- `<A-h>`    Indent current line **left**
- `<A-l>`    Indent current line **right**

Example:
  To move the current line 5 lines down: press `5<A-j>`.

### Moving Selections in Visual Mode                     
The same commands apply in Visual Mode ('v'), Visual Line Mode ('V'), and
Visual Block Mode (<C-v>) to move the entire selection (defualts):
- `<A-k>`    Move visual selection **up** 
- `<A-j>`    Move visual selection **down** 
- `<A-h>`    Indent visual selection **left** 
- `<A-l>`    Indent visual selection **right** 

## Functions description
### Line-mover.setup({config})
Parameters
* {config} `(table|nil)` Module config table. See [configuration](##Configuration).

Behaviour
* Setups module to work properly, use passed config
Usage
```lua
  require('line-mover').setup() -- use default config
  -- OR
  require('line-mover').setup({}) -- replace {} with your config table
```
### Line-mover.move_line({direction})
Parameters  
* {direction} `(string)` Either one of 'up', 'down', 'right', 'left' - direction of movement.

Behaviour
* moves the current line based on direction of movement, that passed to function.

Example of usage
```lua
require('line-mover').move_line('up')
```
### line-mover.move_selection({direction})
Parameters 
* {direction} `(string)` Either one of 'up', 'down', 'right', 'left' - direction of movement.

Behaviour
* moves the current visual selection in direction of movement, that passed to function.

Example of usage
```lua
require('line-mover').move_selection('up') 
```
### Helper functions

```lua
--- @param msg (string) - msg to output with error
--- errors with *msg*
H.print_error = function(msg)
	error("(line-mover.nvim) " .. msg)
end

--- @param name (string) - name of variable for proper error output
--- @param val (any) - variable to check type
--- @param expected (string) - type, that val should match
--- @param allow_nil (bool) - allow val to be nil type
--- Checks type of *val* to match *expected*, if not, output error
H.check_type = function(name, val, expected, allow_nil)
	if (type(val) == expected) or (allow_nil == true and val == nil) then
		return
	end
	H.print_error(name .. " should be type of " .. expected .. ", not " .. type(val))
end

--- @param mode (string) - mode of mapping ('x', 'n', etc)
--- @param lhs  (string) - buttons of mapping 
--- @param rhs (string) - command to execute on lhs press
--- @param opts (table | nil) - any options to take
--- Function maps *lhs* keybind to execute *rhs* command in *mode*
H.map = function(mode, lhs, rhs, opts)
	opts = vim.tbl_deep_extend("force", { silent = true }, opts)
	vim.keymap.set(mode, lhs, rhs, opts)
end

--- @param ref_curpos (table) - table that describes position of cursor before movement
--- @param ref_last_col (int) - last column before movement
--- Corrects cursor to match postition before movement
H.correct_cursor_col = function(ref_curpos, ref_last_col)
	local col_diff = vim.fn.col("$") - ref_last_col
	local new_col = math.max(ref_curpos[3] + col_diff, 1)

	vim.fn.cursor({ vim.fn.line("."), new_col })
end
```
