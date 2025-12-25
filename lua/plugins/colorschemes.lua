require('dracula').setup {
  transparent_bg = true,
  italic_comment = true,
  overrides = function(colors)
    return {
      -- Transparent background
      Normal = { bg = 'NONE' },
      NormalFloat = { bg = 'NONE' },
      FloatBorder = { bg = 'NONE' },
      SignColumn = { bg = 'NONE' },
      EndOfBuffer = { bg = 'NONE' },

      -- Setup mini.statusline
      MiniStatuslineInactive = { fg = colors.white, bg = colors.menu, bold = true },

      -- Setup mini.pick
      MiniFilesBorder = { fg = colors.purple, bg = colors.menu },
      MiniFilesBorderModified = { fg = colors.yellow, bg = colors.menu },
      MiniFilesCursorLine = { fg = colors.white, bg = colors.bg },
      MiniFilesNormal = { fg = colors.fg, bg = colors.menu },
      MiniFilesTitle = { fg = colors.white, bg = colors.menu },
      MiniFilesTitleFocused = { fg = colors.fg, bg = colors.menu },

      -- Setup mini.starter
      MiniStarterCurrent = { fg = colors.fg, bg = 'NONE' },
      MiniStarterHeader = { fg = colors.green, bg = 'NONE' },
      MiniStarterFooter = { fg = colors.green, bg = 'NONE' },
      MiniStarterItem = { fg = colors.white, bg = 'NONE' },
      MiniStarterItemBullet = { fg = colors.cyan, bg = 'NONE' },
      MiniStarterSection = { fg = colors.cyan, bg = 'NONE' },

      -- Setup mini.pick
      MiniPickBorder = { fg = colors.purple, bg = colors.menu },
      MiniPickBorderText = { fg = colors.white, bg = colors.menu },
      MiniPickPrompt = { fg = colors.purple, bg = colors.menu },
      MiniPickMatchCurrent = { fg = colors.white, bg = colors.bg },
      MiniPickMatchRanges = { fg = colors.green, bg = colors.menu },
      MiniPickNormal = { fg = colors.fg, bg = colors.menu },

      -- Setup mini.clue
      MiniClueBorder = { fg = colors.purple, bg = colors.menu },
      MiniClueDescGroup = { fg = colors.green, bg = colors.menu },
      MiniClueDescSingle = { fg = colors.fg, bg = colors.menu },
      MiniClueNextKey = { fg = colors.cyan, bg = colors.menu },
      MiniClueNextKeyWithPostkeys = { fg = colors.cyan, bg = colors.menu },
      MiniClueSeparator = { fg = colors.cyan, bg = colors.menu },
      MiniClueTitle = { fg = colors.white, bg = colors.menu },

      -- Setup mini.notify
      MiniNotifyNormal = { fg = colors.fg, bg = colors.menu },
      MiniNotifyBorder = { fg = colors.purple, bg = colors.menu },
      MiniNotifyTitle = { fg = colors.white, bg = colors.menu },

      -- Setup mini.trailspace
      MiniTrailspace = { bg = colors.bright_red },

      -- Setup harpoon window highlight groups
      HarpoonNormal = { fg = colors.fg, bg = colors.menu },
      HarpoonBorder = { fg = colors.purple, bg = colors.menu },
      HarpoonTitle = { fg = colors.white, bg = colors.menu },

      -- Setup gitconflict
      GitConflictIncomingLabel = {
        fg = colors.bg,
        bg = colors.bright_green,
        bold = true,
        italic = true,
      },
      GitConflictIncoming = { fg = colors.green },
      GitConflictCurrent = { fg = colors.red },
      GitConflictCurrentLabel = {
        fg = colors.bg,
        bg = colors.bright_red,
        bold = true,
        italic = true,
      },

      -- Setup treesitter context
      TreesitterContextBottom = { bg = colors.menu },
    }
  end,
}
