local disable_filetypes = { c = true, cpp = true }
local disable_lsp_formatter = {}

local biome_config_files = {
  'biome.json',
  'Biome.json',
  'biome.jsonc',
  'Biome.jsonc',
  'biome.yaml',
  'Biome.yaml',
  'biome.yml',
  'Biome.yml',
}
local biome_wrapper_dir = vim.fs.joinpath(vim.fn.stdpath('state'), 'conform-biome')
local json_encode = vim.json and vim.json.encode or vim.fn.json_encode
local biome_default_key = '__default__'

local function find_biome_config_file(ctx)
  if not ctx or not ctx.dirname then
    return nil
  end

  local found = vim.fs.find(biome_config_files, {
    path = ctx.dirname,
    upward = true,
    type = 'file',
  })

  return found[1]
end

local function find_biome_root(ctx)
  local config_file = find_biome_config_file(ctx)
  if not config_file then
    return nil
  end

  return vim.fs.dirname(config_file)
end

-- Helper: detect if a project has a Biome config
-- Always allow Biome to run (even without a local config)
local function has_biome_config(_)
  return true
end

local function biome_with_errors_config(config_file)
  if config_file and config_file:match('%.ya?ml$') then
    return nil
  end

  local key = config_file or biome_default_key
  local filename = string.format('%s.json', vim.fn.sha256(key))
  local path = vim.fs.joinpath(biome_wrapper_dir, filename)
  local data = { formatter = { formatWithErrors = true } }

  if config_file then
    data.extends = { config_file }
  end

  local ok, err = pcall(function()
    vim.fn.mkdir(biome_wrapper_dir, 'p')
    local file = assert(io.open(path, 'w'))
    file:write(json_encode(data))
    file:write('\n')
    file:close()
  end)

  if not ok then
    vim.notify(
      ('conform.nvim: failed to enable Biome formatWithErrors (%s)'):format(err),
      vim.log.levels.WARN
    )
    return nil
  end

  return path
end

require('conform').setup {
  notify_on_error = true,
  format_on_save = function(bufnr)
    -- Do not autoformat if it is disabled
    if not vim.g.enable_autoformat then
      return
    end

    local buf_filetype = vim.bo[bufnr].filetype

    -- Disable "format_on_save lsp_fallback" for languages that don't
    -- have a well standardized coding style. You can add additional
    -- languages here or re-enable it for the disabled ones.
    if disable_filetypes[buf_filetype] then
      return nil
    elseif disable_lsp_formatter[buf_filetype] then
      return {
        timeout_ms = 500,
        lsp_format = 'never',
      }
    end

    return {
      timeout_ms = 500,
      lsp_format = 'fallback',
    }
  end,
  formatters = {
    biome = {
      condition = has_biome_config,
      cwd = function(_, ctx)
        return find_biome_root(ctx)
      end,
      append_args = function(_, ctx)
        local wrapper = biome_with_errors_config(find_biome_config_file(ctx))
        if wrapper then
          return { '--config-path', wrapper }
        end
      end,
    },
  },
  ---@module "conform"
  ---@type conform.FiletypeFormatter[]
  formatters_by_ft = {
    lua = { 'stylua' },

    -- Web/TS/JS: Biome only
    html = { 'biome' },
    typescriptreact = { 'biome' },
    typescript = { 'biome' },
    javascriptreact = { 'biome' },
    javascript = { 'biome' },
    markdown = { 'biome' },

    -- Data
    json = { 'biome' },
    jsonc = { 'biome' },
    yaml = { 'biome' },
    toml = { 'biome' },

    -- Backend
    go = { 'gofumpt', 'goimports' },

    python = { 'ruff_format' },
  },
}

-- Keymaps

vim.keymap.set('n', '<leader>f', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local buf_filetype = vim.bo[bufnr].filetype

  local lsp_format = 'fallback'
  if disable_lsp_formatter[buf_filetype] then
    lsp_format = 'never'
  end

  require('conform').format { async = true, lsp_format = lsp_format }
end, { desc = '[F]ormat buffer' })

vim.g.enable_autoformat = true
vim.keymap.set('n', '<leader>tf', function()
  vim.g.enable_autoformat = not vim.g.enable_autoformat

  if vim.g.enable_autoformat then
    vim.notify('Autoformatting enabled', vim.log.levels.INFO)
  else
    vim.notify('Autoformatting disabled', vim.log.levels.INFO)
  end
end, { desc = 'Toggle auto formatting' })
