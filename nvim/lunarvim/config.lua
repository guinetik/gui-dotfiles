-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

-- LunarVim Custom Configuration for development in Java, JavaScript, Python, Rust, and Bash

-- General Settings
lvim.log.level = "warn"
lvim.format_on_save.enabled = true
lvim.colorscheme = "lunar"
lvim.leader = "space"
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.wrap = false -- No line wrapping

-- Key Mappings
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"

-- Terminal mappings
lvim.builtin.terminal.open_mapping = "<C-t>"  -- Ctrl+T opens terminal
lvim.builtin.terminal.size = 15  -- Terminal height

-- Telescope (Command palette, file finder)
lvim.builtin.telescope.defaults.path_display = { "truncate" }
lvim.builtin.telescope.defaults.layout_config = {
  width = 0.8,
  preview_cutoff = 120,
  horizontal = {
    preview_width = function(_, cols, _)
      return math.floor(cols * 0.6)
    end,
  },
}

-- Enable Telescope key mappings
lvim.builtin.which_key.mappings["f"] = {
  name = "Find",
  f = { "<cmd>Telescope find_files<cr>", "Find File" },
  r = { "<cmd>Telescope oldfiles<cr>", "Recent Files" },
  g = { "<cmd>Telescope live_grep<cr>", "Grep" },
  b = { "<cmd>Telescope buffers<cr>", "Buffers" },
  h = { "<cmd>Telescope help_tags<cr>", "Help Tags" },
}

-- Add additional lsp servers for various languages
local lsp_servers = {
  -- Python
  "pyright",
  
  -- JavaScript
  "tsserver",
  "eslint",
  
  -- Rust
  "rust_analyzer",
  
  -- Java 
  "jdtls",
  
  -- Bash
  "bashls",
}

-- Configure automatic installation
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "jdtls" })

-- Formatters setup
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { exe = "black", filetypes = { "python" } },
  { exe = "isort", filetypes = { "python" } },
  { exe = "prettier", filetypes = { "javascript", "typescript", "css", "html", "json", "yaml", "markdown" } },
  { exe = "rustfmt", filetypes = { "rust" } },
  { exe = "shfmt", filetypes = { "sh", "bash" } },
}

-- Linters setup
local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { exe = "flake8", filetypes = { "python" } },
  { exe = "eslint", filetypes = { "javascript", "typescript" } },
  { exe = "shellcheck", filetypes = { "sh", "bash" } },
}

-- Additional plugins
lvim.plugins = {
  -- Telescope Extensions
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  { "nvim-telescope/telescope-project.nvim" },
  
  -- Language Support
  { "simrat39/rust-tools.nvim" },  -- Enhanced Rust support
  { "mfussenegger/nvim-jdtls" },  -- Java support
  
  -- Code Navigation
  { "phaazon/hop.nvim", 
    branch = "v2", 
    config = function()
      require("hop").setup()
    end
  },
  
  -- UI Enhancements
  { "folke/trouble.nvim", 
    dependencies = "nvim-tree/nvim-web-devicons",
    cmd = "TroubleToggle"
  },
  
  -- Git Integration 
  { "tpope/vim-fugitive" },
  
  -- Terminal Integration
  { "akinsho/toggleterm.nvim", version = "*", config = true },
}

-- Auto setup for plugins
lvim.builtin.telescope.extensions = {
  fzf = {
    fuzzy = true,
    override_generic_sorter = true,
    override_file_sorter = true,
    case_mode = "smart_case",
  },
  project = {}
}

-- Configure LSP for Java
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "jdtls" })

-- Special Java setup
lvim.builtin.which_key.mappings["j"] = {
  name = "Java",
  o = { "<cmd>lua require'jdtls'.organize_imports()<cr>", "Organize Imports" },
  v = { "<cmd>lua require('jdtls').extract_variable()<cr>", "Extract Variable" },
  c = { "<cmd>lua require('jdtls').extract_constant()<cr>", "Extract Constant" },
  m = { "<cmd>lua require('jdtls').extract_method()<cr>", "Extract Method" },
}

-- Enhanced UI
lvim.builtin.indentlines.options.show_current_context = true
lvim.builtin.indentlines.options.show_current_context_start = true

-- Hop (quick navigation) keybindings
lvim.keys.normal_mode["<leader>hw"] = ":HopWord<cr>"
lvim.keys.normal_mode["<leader>hl"] = ":HopLine<cr>"
lvim.keys.normal_mode["<leader>hc"] = ":HopChar1<cr>"

-- Trouble integration (diagnostics viewer)
lvim.builtin.which_key.mappings["t"] = {
  name = "Diagnostics",
  t = { "<cmd>TroubleToggle<cr>", "Toggle" },
  w = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "Workspace Diagnostics" },
  d = { "<cmd>TroubleToggle document_diagnostics<cr>", "Document Diagnostics" },
  q = { "<cmd>TroubleToggle quickfix<cr>", "Quickfix" },
  l = { "<cmd>TroubleToggle loclist<cr>", "Loclist" },
  r = { "<cmd>TroubleToggle lsp_references<cr>", "References" },
}

-- Terminal additional configuration
lvim.builtin.terminal.direction = "horizontal"
lvim.builtin.terminal.shade_terminals = true

-- Autocmds - Automatically run commands based on events
lvim.autocommands = {
  {
    {"BufEnter", "BufWinEnter"},
    {
      desc = "Set filetype for bash scripts",
      pattern = {"*.sh"},
      command = "setlocal filetype=bash"
    }
  }
}

-- On_attach function - runs for each LSP
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
end

-- Additional keybindings for navigation
lvim.keys.normal_mode["<C-d>"] = "<C-d>zz"  -- Center cursor after half-page down
lvim.keys.normal_mode["<C-u>"] = "<C-u>zz"  -- Center cursor after half-page up
lvim.keys.normal_mode["n"] = "nzzzv"       -- Center search results
lvim.keys.normal_mode["N"] = "Nzzzv"       -- Center search results

-- Visuals
lvim.builtin.lualine.style = "lvim"