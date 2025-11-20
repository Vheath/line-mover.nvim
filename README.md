# line-mover.nvim
## Author
Груздев Тимур Павлович M3100
## Introduction                                          
LineMover is a lightweight Neovim plugin that provides seamless, repeatable
movement of the current line or a visual selection both vertically (up/down)
and horizontally (indent/unindent).

Plugin provides mappings and lua functions for line-movement(see `:h line-mover.move_line()` and `:h line-mover.mover_selection()`)

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

