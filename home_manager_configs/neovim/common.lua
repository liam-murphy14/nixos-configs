-- Set line numbers
vim.opt.number = true

-- Highlight search results
vim.opt.hlsearch = true

-- Set colorscheme
vim.cmd('colorscheme onedark')

-- Set LaTeX as the TeX flavor
vim.g.tex_flavor = "latex"

-- Enable filetype detection and plugin indenting if autocommands are supported
if vim.fn.has("autocmd") == 1 then
    vim.cmd('filetype plugin indent on')

    -- Use actual tab chars in Makefiles
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "make",
        callback = function()
            vim.opt.tabstop = 8
            vim.opt.shiftwidth = 8
            vim.opt.softtabstop = 0
            vim.opt.expandtab = false
        end,
    })
end

-- Set tab and indentation options
vim.opt.tabstop = 4       -- The width of a TAB is set to 4.
vim.opt.shiftwidth = 4    -- Indents will have a width of 4.
vim.opt.softtabstop = 4   -- Sets the number of columns for a TAB.
vim.opt.expandtab = true   -- Expand TABs to spaces.

-- Set leader key
vim.g.mapleader = ' '

