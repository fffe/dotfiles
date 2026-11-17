-- Neovim 0.11+: bundled parsers and a vendored theme; no automatic installs.
local opt = vim.opt
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.virtualedit = 'all'
opt.scrolloff = 6
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.undofile = true -- Neovim creates its undo directory under stdpath('state').
opt.inccommand = 'split'
opt.completeopt = { 'menu', 'menuone', 'noselect' }

-- Respect explicit tmux fallbacks; otherwise let Neovim detect RGB support.
local palette = vim.env.TMUX and vim.env.TMUX ~= '' and vim.env.DOTFILES_TMUX_COLORS
if palette and palette ~= '' then
  opt.termguicolors = palette == 'truecolor'
elseif vim.env.COLORTERM == 'truecolor' or vim.env.COLORTERM == '24bit' then
  opt.termguicolors = true
elseif vim.env.TERM == 'dumb' or vim.env.TERM == 'linux' or vim.env.TERM == 'screen' then
  opt.termguicolors = false
end

if opt.termguicolors:get() then
  vim.cmd.packadd('catppuccin')
  local catppuccin = require('catppuccin')
  catppuccin.flavours = { latte = 1, mocha = 4 }
  catppuccin.setup({
    flavour = 'auto',
    color_overrides = {
      mocha = { base = '#0c0c0c', mantle = '#080808', crust = '#040404' },
    },
  })
  vim.cmd.colorscheme('catppuccin')
elseif palette == '256' or (palette ~= 'ansi' and (vim.env.TERM or ''):match('256color$')) then
  -- The Lua theme forces RGB; the Vim port also supplies indexed colors.
  vim.cmd.colorscheme('catppuccin_mocha')
end

-- Only bundled grammars for now. Older builds may omit some of these.
local parsers = {
  c = true, diff = true, lua = true, markdown = true, markdown_inline = true,
  query = true, vim = true, vimdoc = true,
}
local group = vim.api.nvim_create_augroup('dotfiles_editing', { clear = true })
-- Display wrapping is window-local; reset it when a window changes buffers.
local prose = { text = true, markdown = true, rst = true, asciidoc = true, gitcommit = true, mail = true }
vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter' }, {
  group = group,
  callback = function(event)
    local enabled = prose[vim.bo[event.buf].filetype] == true
    vim.wo.linebreak = enabled
    vim.wo.breakindent = enabled
    if enabled then
      vim.wo.wrap = true
    end
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  callback = function(event)
    local language = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
    if parsers[language] then
      -- Missing parsers retain regular syntax highlighting; never download one.
      pcall(vim.treesitter.start, event.buf, language)
    end
  end,
})

-- Future servers can be configured with vim.lsp.config / vim.lsp.enable.
-- No servers are enabled here; use native completion when one attaches.
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/completion', event.buf) then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end
  end,
})
