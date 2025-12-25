local disable_filetypes = { c = true, cpp = true }
local disable_lsp_formatter = {}

local biome_root_markers = {
  'biome.json',
  'Biome.json',
  'biome.jsonc',
  'Biome.jsonc',
  'biome.yaml',
  'Biome.yaml',
  'biome.yml',
  'Biome.yml',
  'package.json',
  '.git',
}
local util = require 'conform.util'

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
      command = 'biome',
      args = { 'format', '--stdin-file-path', '$FILENAME' },
      stdin = true,
      tmpfile_format = false,
      cwd = util.root_file(biome_root_markers),
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
