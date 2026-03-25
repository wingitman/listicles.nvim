--- listicles.nvim – floating window management
--- Handles creating, showing, hiding, and cleaning up the terminal window
--- that runs the listicles binary.

local M = {}

--- State for the single managed window instance.
local state = {
  buf = nil,   -- terminal buffer handle
  win = nil,   -- floating window handle
  job = nil,   -- terminal job id (for sending keys if needed)
}

--- Returns true if the window is currently open and valid.
function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

--- Returns true if the buffer exists and is valid (may be hidden).
function M.has_buf()
  return state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf)
end

--- Compute floating window dimensions from config opts.
--- @param opts table  Plugin config (width, height, border, etc.)
--- @return table      nvim_open_win config table
local function win_config(opts)
  local total_w = vim.o.columns
  local total_h = vim.o.lines

  local w = math.floor(total_w * opts.width)
  local h = math.floor(total_h * opts.height)
  local row = math.floor((total_h - h) / 2)
  local col = math.floor((total_w - w) / 2)

  return {
    relative = "editor",
    style    = "minimal",
    border   = opts.border,
    width    = w,
    height   = h,
    row      = row,
    col      = col,
    zindex   = 50,
  }
end

--- Open a new floating window running the listicle binary.
--- @param opts       table   Plugin config
--- @param cmd        string  Full shell command to run
--- @param on_exit    function  Called when the process exits (no args)
function M.open(opts, cmd, on_exit)
  if M.is_open() then
    return
  end

  -- Create a scratch buffer if we don't already have one.
  if not M.has_buf() then
    state.buf = vim.api.nvim_create_buf(false, true)
  end

  local wcfg = win_config(opts)
  state.win = vim.api.nvim_open_win(state.buf, true, wcfg)

  -- Apply window-local options.
  vim.wo[state.win].winblend = opts.winblend or 0
  vim.wo[state.win].winhighlight = "Normal:ListiclesNormal,FloatBorder:ListiclesBorder"
  vim.wo[state.win].cursorline = false

  -- Start the terminal job inside the buffer.
  state.job = vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code, _)
      -- Defer all teardown to the next event loop tick so the terminal job
      -- has fully finished before we close the window, wipe the buffer, and
      -- act on the exit (e.g. :edit a file). Without this, the window/buffer
      -- teardown can race with the scheduled :edit and crash Neovim.
      vim.schedule(function()
        -- Close window on exit.
        if M.is_open() then
          vim.api.nvim_win_close(state.win, true)
          state.win = nil
        end
        -- Wipe buffer so it doesn't linger.
        if M.has_buf() then
          vim.api.nvim_buf_delete(state.buf, { force = true })
          state.buf = nil
        end
        state.job = nil
        if on_exit then
          on_exit(exit_code)
        end
      end)
    end,
  })

  -- Enter terminal insert mode automatically.
  vim.cmd("startinsert")
end

--- Close the floating window without killing the process (hides it).
--- In practice listicle always exits itself, so this is a safety hatch.
function M.close()
  if M.is_open() then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end
end

return M
