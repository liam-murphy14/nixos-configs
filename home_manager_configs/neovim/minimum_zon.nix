{ pkgs, ... }:

let
  jdtlsSetupRaw = builtins.readFile ./ftplugin/java.lua;

  rootMarkersBlockBemolZon = "{ '.bemol' }";
  bemolOnAttachBlockBemolZon = "on_attach = bemol,";
  jdtlsSetupFinalBemolZon = builtins.replaceStrings [ "JDTLS_PATH_BLOCK" "LOMBOK_PATH_BLOCK" "''--ROOT_MARKERS_BLOCK" "--BEMOL_ON_ATTACH_BLOCK" ] [ "${pkgs.jdt-language-server}" "${pkgs.lombok}" rootMarkersBlockBemolZon bemolOnAttachBlockBemolZon ] jdtlsSetupRaw;

  pathToJdtlsConfig = if pkgs.stdenv.isDarwin then pkgs.jdt-language-server + /share/java/jdtls/config_mac/config.ini else pkgs.jdt-language-server + /share/java/jdtls/config_linux/config.ini;
in

{

  home.file.".config/nvim/ftplugin/java.lua".text = jdtlsSetupFinalBemolZon;
  home.file.".cache/jdtls/config/config.ini".source = pathToJdtlsConfig;

  programs.neovim = {
    enable = true;

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraLuaConfig = builtins.readFile ./common.lua;
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
        config = builtins.readFile ./plugins/completions-minimum-zon.lua;
        type = "lua";
      }
      {
        plugin = nvim-jdtls;
        # init in ftplugin/java.lua
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
      {
        plugin = comment-nvim;
        config = builtins.readFile ./plugins/comment-nvim.lua;
        type = "lua";
      }
      {
        plugin = nvim-web-devicons;
        # init in oil.lua
      }
      {
        plugin = oil-nvim;
        config = builtins.readFile ./plugins/oil.lua;
        type = "lua";
      }
      {
        plugin = neoscroll-nvim;
        config = builtins.readFile ./plugins/neoscroll.lua;
        type = "lua";
      }
    ];

    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    extraPackages = with pkgs; [
      nil
      lua-language-server
      jdt-language-server
      lombok
    ];
  };
}
