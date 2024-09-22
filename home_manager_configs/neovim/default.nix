{ pkgs, lib, config, ... }:

{
  options.nix_neovim = {
    enableCopilot = lib.mkOption { default = false; type = lib.types.bool; };
  };

  config = {
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
      ] ++ lib.lists.optional config.nix_neovim.enableCopilot {
        plugin = copilot-vim;
        # config = builtins.readFile ./plugins/copilot.lua;
        # type = "lua";
      };

      withNodeJs = true;
      extraPackages = with pkgs; [
        nil
        pyright
        typescript
        lua-language-server
        nodePackages_latest.typescript-language-server
        nodePackages_latest.svelte-language-server
        nodePackages_latest."@tailwindcss/language-server"
        nodePackages_latest."@prisma/language-server"
      ] ++ lib.lists.optional config.nix_neovim.enableCopilot nodePackages_latest.nodejs;
    };
  };
}
