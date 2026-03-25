# listicle.nvim

A Neovim plugin that wraps the [listicle](https://github.com/listicle/listicle)
terminal file explorer in a floating window, replacing Neo-tree / netrw for
directory navigation.

## Requirements

- Neovim >= 0.9
- The `listicle` binary on your `$PATH` (built from the listicle repo with
  `make install`, or placed manually)

## Installation

### lazy.nvim

```lua
{
  "listicle/listicle.nvim",
  config = function()
    require("listicle").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "listicle/listicle.nvim",
  config = function()
    require("listicle").setup()
  end,
}
```

## Usage

| Command            | Description                                   |
|--------------------|-----------------------------------------------|
| `:Listicle [dir]`  | Open listicle, optionally starting in `[dir]` |
| `:ListicleToggle`  | Toggle the listicle window                    |

The default keymap is `<leader>e`. Override or disable it via `setup()`.

Inside listicle:

- **Navigate** with arrow keys or `hjkl` (if vim preset is enabled in
  `~/.config/listicle/listicle.toml`)
- **Enter** on a **directory** → closes listicle and `:lcd`s Neovim into it
- **Enter** on a **file** → closes listicle and opens the file in Neovim
  (respects `open_action`)
- **`q` / `Esc`** → close listicle with no side effects

## Configuration

```lua
require("listicle").setup({
  -- Path to the listicle binary (default: "listicle" from $PATH).
  bin = "listicle",

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

  -- Keymap to toggle listicle. Set to false to disable.
  keymap = "<leader>e",
})
```

### Highlight groups

| Group            | Default link  | Purpose               |
|------------------|---------------|-----------------------|
| `ListicleNormal` | `NormalFloat` | Window background     |
| `ListicleBorder` | `FloatBorder` | Window border         |

Override before or after `setup()`:

```lua
vim.api.nvim_set_hl(0, "ListicleBorder", { fg = "#7aa2f7" })
```

## How it works

1. `listicle` is launched in a Neovim floating terminal buffer with two temp
   files passed via `--cd-file` and `--open-file`.
2. When you press **Enter** on a directory, `listicle` writes that path to
   `--cd-file` and exits.
3. When you press **Enter** on a file, `listicle` writes that path to
   `--open-file` (and the parent dir to `--cd-file`) and exits.
4. The plugin reads both files and calls `:lcd` / `:edit` (or whichever
   actions you've configured) in a `vim.schedule` callback.

This is the same IPC pattern used by the bundled shell wrappers
(`listicle.bash`, `listicle.zsh`, etc.) — the plugin just replaces the shell
function with Lua.
