--- listicles.nvim
--- A Neovim wrapper for the listicles terminal file explorer.
--- https://github.com/wingitman/listicles

local window = require("listicles.window")

local M = {}

--- Default configuration.
local defaults = {
  -- Path to the listicles binary. "listicles" relies on $PATH.
  bin = "listicles",

  -- Floating window dimensions (fraction of editor size).
  width  = 0.85,
  height = 0.85,

  -- Window border style. See :h nvim_open_win for valid values.
  border = "rounded",

  -- Window transparency (0–100). 0 = opaque.
  winblend = 0,

  -- How to open a selected file. Options:
  --   "edit"    – open in current window  (:edit)
  --   "split"   – horizontal split        (:split)
  --   "vsplit"  – vertical split          (:vsplit)
  --   "tabedit" – new tab                 (:tabedit)
  open_action = "edit",

  -- Whether to change Neovim's cwd when a directory is selected.
  -- Uses :lcd (window-local) so other windows are unaffected.
  -- Set to "cd" for global, "tcd" for tab-local, or false to disable.
  cd_action = "lcd",

  -- Keymap to open listicles. Set to false to disable.
  keymap = "<leader>e",
}

--- Resolved config (populated by setup()).
M.config = {}

--- Ensure highlight groups exist.
local function define_highlights()
  -- Fall back to built-in float groups if the user hasn't customised them.
  if vim.fn.hlexists("ListiclesNormal") == 0 then
    vim.api.nvim_set_hl(0, "ListiclesNormal", { link = "NormalFloat" })
  end
  if vim.fn.hlexists("ListiclesBorder") == 0 then
    vim.api.nvim_set_hl(0, "ListiclesBorder", { link = "FloatBorder" })
  end
end

--- Act on the results written by listicles after it exits.
--- @param cd_file    string  Temp file that may contain a directory path.
--- @param open_file  string  Temp file that may contain a file path.
local function handle_exit(cd_file, open_file)
  -- Read the file path first (takes priority).
  local file_path = nil
  local f = io.open(open_file, "r")
  if f then
    file_path = f:read("*l")
    f:close()
  end
  os.remove(open_file)

  -- Read the cd path.
  local dir_path = nil
  local d = io.open(cd_file, "r")
  if d then
    dir_path = d:read("*l")
    d:close()
  end
  os.remove(cd_file)

  -- Schedule so we're back in a normal Neovim context after the terminal exits.
  vim.schedule(function()
    -- Change directory if a dir was written.
    if dir_path and dir_path ~= "" and M.config.cd_action then
      pcall(vim.cmd, M.config.cd_action .. " " .. vim.fn.fnameescape(dir_path))
    end

    -- Open the file if one was written.
    if file_path and file_path ~= "" then
      local action = M.config.open_action or "edit"
      pcall(vim.cmd, action .. " " .. vim.fn.fnameescape(file_path))
    end
  end)
end

--- Open the listicles floating window.
--- @param start_dir string|nil  Directory to start in (defaults to cwd).
function M.open(start_dir)
  if window.is_open() then
    return
  end

  define_highlights()

  -- Create temp files for IPC.
  local cd_file   = vim.fn.tempname()
  local open_file = vim.fn.tempname()

  -- Determine starting directory.
  local dir = start_dir
  if not dir or dir == "" then
    -- Default to the directory of the current buffer, falling back to cwd.
    local buf_path = vim.api.nvim_buf_get_name(0)
    if buf_path ~= "" then
      dir = vim.fn.fnamemodify(buf_path, ":p:h")
    else
      dir = vim.fn.getcwd()
    end
  end

  local cmd = table.concat({
    vim.fn.shellescape(M.config.bin),
    "--cd-file",   vim.fn.shellescape(cd_file),
    "--open-file", vim.fn.shellescape(open_file),
    "--dir",       vim.fn.shellescape(dir),
  }, " ")

  window.open(M.config, cmd, function(_exit_code)
    handle_exit(cd_file, open_file)
  end)
end

--- Toggle the listicles window (open if closed, no-op if already open since
--- listicles handles its own quit key).
function M.toggle(start_dir)
  if window.is_open() then
    window.close()
  else
    M.open(start_dir)
  end
end

--- Setup – call this once from your config.
--- @param opts table|nil  Partial config table to override defaults.
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Register default keymap unless disabled.
  if M.config.keymap then
    vim.keymap.set("n", M.config.keymap, function()
      M.toggle()
    end, { desc = "Toggle listicles file explorer", silent = true })
  end
end

return M
