{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraConfig = builtins.readFile ./common.vim;
    plugins = with pkgs.vimPlugins; [
      {
        plugin = onedark-nvim;
        config = builtins.readFile ./plugins/onedark.lua;
        type = "lua";
      }
      {
        plugin = lualine-nvim;
        config = builtins.readFile ./plugins/lualine.lua;
        type = "lua";
      }
      {
        plugin = nvim-treesitter.withAllGrammars;
        config = builtins.readFile ./plugins/treesitter.lua;
        type = "lua";
      }
      {
        plugin = nvim-lspconfig;
        # init in completions.lua
      }
      {
        plugin = nvim-cmp;
        # init in completions.lua
      }
      {
        plugin = luasnip;
        # init in completions.lua
      }
      {
        plugin = cmp-nvim-lsp;
        config = builtins.readFile ./plugins/completions.lua;
        type = "lua";
      }
      {
        plugin = telescope-nvim;
        config = builtins.readFile ./plugins/telescope.lua;
        type = "lua";
      }
      {
        plugin = nvim-autopairs;
        config = builtins.readFile ./plugins/autopairs.lua;
        type = "lua";
      }
    ];

    withNodeJs = true;
    extraPackages = with pkgs; [ nil nodePackages.pyright lua-language-server ];
  };
}
