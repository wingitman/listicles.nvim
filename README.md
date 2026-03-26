# listicles.nvim

A Neovim plugin that wraps the [listicles](https://github.com/wingitman/listicles)
terminal file explorer in a floating window for directory navigation.

## Requirements

- Neovim >= 0.9
- Go 1.21+ (to build)
- [listicles](https://github.com/wingitman/listicles)

## Installation

### lazy.nvim

```lua
{
  "wingitman/listicles.nvim",
  config = function()
    require("listicles").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "wingitman/listicles.nvim",
  config = function()
    require("listicles").setup()
  end,
}
```

## Usage

| Command              | Description                                     |
|----------------------|-------------------------------------------------|
| `:Listicles [dir]`   | Open listicles, optionally starting in `[dir]`  |
| `:ListiclesToggle`   | Toggle the listicles window                     |

The default keymap is `<leader>e`. Override or disable it via `setup()`.

Inside listicles:

- **Navigate** with arrow keys or `hjkl` (if vim preset is enabled in
  `~/.config/listicles/listicles.toml`)
- **Enter** on a **directory** → closes listicles and `:lcd`s Neovim into it
- **Enter** on a **file** → closes listicles and opens the file in Neovim
  (respects `open_action`)
- **`q` / `Esc`** → close listicles with no side effects

## Configuration

```lua
require("listicles").setup({
  -- Path to the listicles binary (default: "listicles" from $PATH).
  bin = "listicles",

  -- Floating window dimensions as fraction of editor size.
  width  = 0.85,
  height = 0.85,

  -- Border style: "rounded", "single", "double", "shadow", "none", …
  border = "rounded",

  -- Window transparency 0–100 (0 = opaque). Requires a compositor.
  winblend = 0,

  -- How to open a selected file:
  --   "edit"    current window
  --   "split"   horizontal split
  --   "vsplit"  vertical split
  --   "tabedit" new tab
  open_action = "edit",

  -- How to cd when a directory is selected:
  --   "lcd"  window-local (default, safest)
  --   "tcd"  tab-local
  --   "cd"   global
  --   false  disable
  cd_action = "lcd",

  -- Keymap to toggle listicles. Set to false to disable.
  keymap = "<leader>e",
})
```

### Highlight groups

| Group              | Default link  | Purpose               |
|--------------------|---------------|-----------------------|
| `ListiclesNormal`  | `NormalFloat` | Window background     |
| `ListiclesBorder`  | `FloatBorder` | Window border         |

Override before or after `setup()`:

```lua
vim.api.nvim_set_hl(0, "ListiclesBorder", { fg = "#7aa2f7" })
```

## How it works

1. `listicles` is launched in a Neovim floating terminal buffer with two temp
   files passed via `--cd-file` and `--open-file`.
2. When you press **Enter** on a directory, `listicles` writes that path to
   `--cd-file` and exits.
3. When you press **Enter** on a file, `listicles` writes that path to
   `--open-file` (and the parent dir to `--cd-file`) and exits.
4. The plugin reads both files and calls `:lcd` / `:edit` (or whichever
   actions you've configured) in a `vim.schedule` callback.

This is the same IPC pattern used by the bundled shell wrappers
(`listicles.bash`, `listicles.zsh`, etc.) — the plugin just replaces the shell
function with Lua.


## Support
<a href='https://ko-fi.com/W7W21WP5L7' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi4.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

Copyright (c) 2026 [delbysoft](https://github.com/wingitman)
