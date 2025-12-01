local augroup = vim.api.nvim_create_augroup('DVT MiniFiles', { clear = true })

require('mini.files').setup {
  mappings = {
    close = 'q',
    go_in = '',
    go_in_plus = '',
    go_out = '<left>',
    go_out_plus = '',
    mark_set = 'm',
    mark_goto = "'",
    reset = '<BS>',
    reveal_cwd = '@',
    show_help = '?',
    synchronize = '<CR>',
    trim_left = '<',
    trim_right = '>',
  },
  options = {
    permanent_delete = false,
  },
  windows = {
    max_number = 3,
  },
}

-- Auto-expand empty & nested dirs
-- See https://github.com/echasnovski/mini.nvim/discussions/1184
local expand_single_dir
expand_single_dir = vim.schedule_wrap(function()
  local is_one_dir = vim.api.nvim_buf_line_count(0) == 1
    and (MiniFiles.get_fs_entry() or {}).fs_type == 'directory'
  if not is_one_dir then
    return
  end
  MiniFiles.go_in { close_on_file = true }
  expand_single_dir()
end)

local go_in_and_expand = function()
  local fs_entry = MiniFiles.get_fs_entry()
  local should_expand = fs_entry ~= nil and fs_entry.fs_type == 'file'

  MiniFiles.go_in { close_on_file = true }

  -- Need to check otherwise it will throw error because the mini.files window was closed
  if not should_expand then
    expand_single_dir()
  end
end

--- @param open_current_file boolean If true, will open mini.files in the current file, otherwise opents on cwd.
local mini_files_toggle = function(open_current_file)
  if not MiniFiles.close() then
    local current_file = vim.api.nvim_buf_get_name(0)
    -- Needed for starter dashboard
    if vim.fn.filereadable(current_file) == 0 or not open_current_file then
      MiniFiles.open()
    else
      MiniFiles.open(current_file, true)
    end
  end
end
vim.keymap.set('n', '<leader>e', function()
  mini_files_toggle(true)
end, { desc = 'Toggle [e]xplorer on current file' })
vim.keymap.set('n', '<leader>E', function()
  mini_files_toggle(false)
end, { desc = 'Toggle [E]xplorer on cwd' })

local map_split = function(buf_id, lhs, direction)
  local rhs = function()
    local get_entry = MiniFiles.get_fs_entry()

    -- Don't do anything if dealing with directory
    if get_entry == nil or get_entry.fs_type == 'directory' then
      return
    end

    -- Make new window
    local cur_target = MiniFiles.get_explorer_state().target_window
    local new_target = vim.api.nvim_win_call(cur_target, function()
      vim.cmd(direction .. ' split')
      return vim.api.nvim_get_current_win()
    end)

    pcall(vim.fn.win_execute, new_target, 'edit ' .. get_entry.path)
    MiniFiles.close()
    pcall(vim.api.nvim_set_current_win, new_target)
  end

  -- Adding `desc` will result into `show_help` entries
  local desc = 'Split ' .. direction
  vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
end

local show_dotfiles = true

local filter_show_all = function()
  return true
end

local filter_hide_dotfiles = function(fs_entry)
  return not vim.startswith(fs_entry.name, '.')
end

local toggle_dotfiles = function()
  show_dotfiles = not show_dotfiles
  local new_filter = show_dotfiles and filter_show_all or filter_hide_dotfiles
  MiniFiles.refresh { content = { filter = new_filter } }
end

local files_grug_far = function(_)
  local cur_entry_path = MiniFiles.get_fs_entry().path
  local prefills = { paths = vim.fs.dirname(cur_entry_path) }

  local grug_far = require 'grug-far'

  if not grug_far.has_instance 'explorer' then
    grug_far.open {
      instanceName = 'explorer',
      prefills = prefills,
      staticTitle = 'Find and Replace from Explorer',
    }
  else
    grug_far.get_instance('explorer'):open()
    grug_far.get_instance('explorer'):update_input_values(prefills, false)
  end
end

vim.api.nvim_create_autocmd('User', {
  group = augroup,
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local buf_id = args.data.buf_id

    vim.b[buf_id].minianimate_disable = true

    vim.keymap.set('n', 'G', 'G', { buffer = buf_id })
    vim.keymap.set('n', '<C-u>', '<C-u>', { buffer = buf_id })
    vim.keymap.set('n', '<C-d>', '<C-d>', { buffer = buf_id })

    vim.keymap.set('n', '<right>', go_in_and_expand, { buffer = buf_id, desc = 'Go in and expand' })

    map_split(buf_id, '<C-h>', 'belowright horizontal')
    map_split(buf_id, '<C-v>', 'belowright vertical')

    vim.keymap.set('n', '.', toggle_dotfiles, { buffer = buf_id, desc = 'Toggle hidden [.]files' })

    vim.keymap.set('n', '<ESC>', MiniFiles.close, { buffer = buf_id, desc = 'Close Mini Files' })
    vim.keymap.set('i', '<C-c>', MiniFiles.close, { buffer = buf_id, desc = 'Close Mini Files' })

    -- Helpers to create/rename/delete
    local function get_current_dir()
      local entry = MiniFiles.get_fs_entry()
      if entry == nil then
        return vim.uv.cwd()
      end
      if entry.fs_type == 'directory' then
        return entry.path
      end
      return vim.fs.dirname(entry.path)
    end

    -- Create file
    vim.keymap.set('n', 'a', function()
      local dir = get_current_dir()
      local new_path = vim.fn.input('New file: ', dir .. '/', 'file')
      if new_path == nil or new_path == '' then
        return
      end
      -- Ensure parent directories
      vim.fn.mkdir(vim.fs.dirname(new_path), 'p')
      local ok, f = pcall(io.open, new_path, 'w')
      if ok and f then
        f:close()
      else
        vim.notify('Could not create file: ' .. new_path, vim.log.levels.ERROR)
        return
      end
      MiniFiles.refresh {}
    end, { buffer = buf_id, desc = 'Create [a] file' })

    -- Create directory
    vim.keymap.set('n', 'A', function()
      local dir = get_current_dir()
      local new_dir = vim.fn.input('New directory: ', dir .. '/', 'file')
      if new_dir == nil or new_dir == '' then
        return
      end
      vim.fn.mkdir(new_dir, 'p')
      MiniFiles.refresh {}
    end, { buffer = buf_id, desc = 'Create [A] directory' })

    -- Rename current entry
    vim.keymap.set('n', 'r', function()
      local entry = MiniFiles.get_fs_entry()
      if entry == nil then
        return
      end
      local new_path = vim.fn.input('Rename to: ', entry.path, 'file')
      if new_path == nil or new_path == '' or new_path == entry.path then
        return
      end
      local ok, err = os.rename(entry.path, new_path)
      if not ok then
        vim.notify('Could not rename: ' .. (err or ''), vim.log.levels.ERROR)
        return
      end
      MiniFiles.refresh {}
    end, { buffer = buf_id, desc = '[R]ename' })

    -- Delete current entry (uses Vim delete; permanent_delete=false in setup keeps safety elsewhere)
    vim.keymap.set('n', 'x', function()
      local entry = MiniFiles.get_fs_entry()
      if entry == nil then
        return
      end
      local confirm = vim.fn.confirm('Delete\n' .. entry.path .. '?', '&Yes\n&No', 2)
      if confirm ~= 1 then
        return
      end
      if entry.fs_type == 'directory' then
        vim.fn.delete(entry.path, 'rf')
      else
        vim.fn.delete(entry.path)
      end
      MiniFiles.refresh {}
    end, { buffer = buf_id, desc = 'Delete (x)' })

    vim.keymap.set(
      'n',
      '<leader>sR',
      files_grug_far,
      { buffer = buf_id, desc = 'Search and Replace in directory' }
    )
    vim.keymap.set('n', '<leader>sg', function()
      local cur_entry_path = MiniFiles.get_fs_entry().path
      local path = vim.fs.dirname(cur_entry_path)

      MiniPick.builtin.grep_live({}, {
        source = {
          cwd = path,
        },
      })
    end, { buffer = buf_id, desc = 'Grep in directory' })
    vim.keymap.set('n', '<leader>sf', function()
      local cur_entry_path = MiniFiles.get_fs_entry().path
      local path = vim.fs.dirname(cur_entry_path)

      MiniPick.builtin.files({}, {
        source = {
          cwd = path,
        },
      })
    end, { buffer = buf_id, desc = 'Find files in directory' })
  end,
})

vim.api.nvim_create_autocmd('User', {
  group = augroup,
  pattern = 'MiniFilesWindowUpdate',
  callback = function(args)
    -- Only show number column in the current directory
    local current_buf = args.buf == args.data.buf_id
    vim.wo[args.data.win_id].number = current_buf
    vim.wo[args.data.win_id].relativenumber = current_buf
  end,
})

-- Use to try and automatically detect
vim.api.nvim_create_autocmd('User', {
  group = augroup,
  pattern = { 'MiniFilesActionRename', 'MiniFilesActionMove' },
  callback = function(args)
    local from = args.data.from
    local to = args.data.to
    local lsp_changes = {
      files = {
        {
          oldUri = vim.uri_from_fname(from),
          newUri = vim.uri_from_fname(to),
        },
      },
    }

    -- LSP integation
    -- See https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/rename.lua#L85
    local clients = vim.lsp.get_clients()
    for _, client in ipairs(clients) do
      local lsp_rename_files_method = vim.lsp.protocol.Methods.workspace_willRenameFiles
      if client:supports_method(lsp_rename_files_method) then
        local resp = client:request_sync(lsp_rename_files_method, lsp_changes, 1000, 0)
        if resp and resp.result ~= nil then
          vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
        end
      end
    end

    for _, client in ipairs(clients) do
      local lsp_rename_files_method = vim.lsp.protocol.Methods.workspace_didRenameFiles
      if client:supports_method(lsp_rename_files_method) then
        client:notify(lsp_rename_files_method, lsp_changes)
      end
    end

    -- Auto file to Git in order for it to detect file was renamed or moved
    -- We check because if the git add command runs it'll notify the error
    local is_inside_git_repo = vim
      .system({
        'git',
        'rev-parse',
        '--is-inside-work-tree',
      }, { text = true })
      :wait()
    if is_inside_git_repo.code ~= 0 then
      return
    end

    pcall(vim.cmd, 'Git add ' .. from .. ' ' .. to)
  end,
})
