{ pkgs, lib, config, ... }:

let
  jdtlsSetupRaw = builtins.readFile ./ftplugin/java.lua;
  rootMarkersBlock = "{'gradlew', '.git', 'mvnw', 'build.gradle', 'settings.gradle', 'pom.xml'}";
  jdtlsSetupFinal = builtins.replaceStrings [ "JDTLS_PATH_BLOCK" "LOMBOK_PATH_BLOCK" "''--ROOT_MARKERS_BLOCK" ] [ "${pkgs.jdt-language-server}" "${pkgs.lombok}" rootMarkersBlock ] jdtlsSetupRaw;

  rootMarkersBlockBemolZon = "{ '.bemol' }";
  bemolOnAttachBlockBemolZon = "on_attach = bemol,";
  jdtlsSetupFinalBemolZon = builtins.replaceStrings [ "JDTLS_PATH_BLOCK" "LOMBOK_PATH_BLOCK" "''--ROOT_MARKERS_BLOCK" "--BEMOL_ON_ATTACH_BLOCK" ] [ "${pkgs.jdt-language-server}" "${pkgs.lombok}" rootMarkersBlockBemolZon bemolOnAttachBlockBemolZon ] jdtlsSetupRaw;

  pathToJdtlsConfig = if pkgs.stdenv.isDarwin then pkgs.jdt-language-server + /share/java/jdtls/config_mac/config.ini else pkgs.jdt-language-server + /share/java/jdtls/config_linux/config.ini;
in

{
  options.nix_neovim = {
    enableCopilot = lib.mkOption { default = false; type = lib.types.bool; };
    enableZonBemol = lib.mkOption { default = false; type = lib.types.bool; };
  };

  config = {

    home.file.".config/nvim/ftplugin/java.lua".text = if config.nix_neovim.enableZonBemol then jdtlsSetupFinalBemolZon else jdtlsSetupFinal;
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
          config = builtins.readFile ./plugins/completions.lua;
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
      ]; # ++ lib.lists.optional config.nix_neovim.enableCopilot {
      # no more subscription
      # plugin = copilot-vim;
      # no config needed
      # kk};

      withNodeJs = true;
      withPython3 = true;
      withRuby = true;
      extraPackages = with pkgs; [
        nil
        pyright
        typescript
        lua-language-server
        nodePackages_latest.typescript-language-server
        nodePackages_latest.svelte-language-server
        nodePackages_latest."@tailwindcss/language-server"
        jdt-language-server
        lombok
        rust-analyzer
      ];
    };
  };
}
