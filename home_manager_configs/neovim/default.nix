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
        plugin = nvim-lspconfig;
      }
      {
        plugin = nvim-treesitter.withAllGrammars;
        # config = ./;
        # type = "lua";
      }
      {
        plugin = nvim-cmp;
      }
      {
        plugin = luasnip;
      }
      {
        plugin = cmp-nvim-lsp;
        config = builtins.readFile ./plugins/completions.lua;
        type = "lua";
      }
      {
        plugin = telescope-nvim;
        # config = ./;
        # type = "lua";
      }
      {
        plugin = nvim-autopairs;
        # config = ./;
        # type = "lua";
      }
    ];

    withNodeJs = true;
    extraPackages = with pkgs; [ nil nodePackages.pyright ];
  };
}
