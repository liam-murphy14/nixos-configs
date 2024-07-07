# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, config, ... }:

{
  # CORE
  imports =
    [
      ./gui_apps.nix
      ./../nix_modules/nix_core.nix
    ];
  # NETWORK
  networking.hostName = "mbp-nix-darwin";
  networking.computerName = "mbp-nix-darwin";

  nix_core.allowUnfree = true;
  nix_core.hostPlatform = "x86_64-darwin";
  nix_core.autoOptimiseStore = false;

  services.nix-daemon.enable = true;
  programs.nix-index.enable = true;

  # FONTS
  fonts = {
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
    ];
  };

  # USERS
  users.users.liammurphy = {
    home = "/Users/liammurphy";
    description = "Liam Murphy";
  };

  nix.settings.trusted-users = [ "liammurphy" ];

  # PACKAGES
  environment.systemPackages = with pkgs; [
    neovim
  ];
  environment.variables.EDITOR = "nvim";
  environment.pathsToLink = [ "/share/zsh" ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.zsh.enable = true;
  programs.zsh.promptInit = "autoload -U promptinit && promptinit && prompt default && setopt prompt_sp";
  environment.shells = [
    pkgs.zsh
  ];

  system = {
    # configurationRevision = self.rev or self.dirtyRev or null;
    stateVersion = 4;
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    defaults = {
      smb.NetBIOSName = "mbp-nix-darwin";
      dock.show-recents = false;
      # customize finder
      finder = {
        _FXShowPosixPathInTitle = true; # show full path in finder title
        AppleShowAllExtensions = true; # show all file extensions
        FXEnableExtensionChangeWarning = false; # disable warning when changing file extension
        QuitMenuItem = true; # enable quit menu item
        ShowPathbar = true; # show path bar
        ShowStatusBar = true; # show status bar
      };

      # customize trackpad
      trackpad = {
        # tap - 轻触触摸板, click - 点击触摸板
        Clicking = false; # disable tap to click(轻触触摸板相当于点击)
        TrackpadRightClick = true; # enable two finger right click
        TrackpadThreeFingerDrag = false; # enable three finger drag
      };

      # customize macOS
      NSGlobalDomain = {
        # `defaults read NSGlobalDomain "xxx"`
        "com.apple.swipescrolldirection" = true; # enable natural scrolling(default to true)
        "com.apple.sound.beep.feedback" = 0; # disable beep sound when pressing volume up/down key
        AppleInterfaceStyle = "Dark"; # dark mode
        AppleKeyboardUIMode = 3; # Mode 3 enables full keyboard control.
        ApplePressAndHoldEnabled = false; # enable press and hold

        # If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
        # This is very useful for vim users, they use `hjkl` to move cursor.
        # sets how long it takes before it starts repeating.
        InitialKeyRepeat = 15; # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
        # sets how fast it repeats once it starts. 
        KeyRepeat = 2; # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)

        NSAutomaticCapitalizationEnabled = false; # disable auto capitalization(自动大写)
        NSAutomaticDashSubstitutionEnabled = false; # disable auto dash substitution(智能破折号替换)
        NSAutomaticPeriodSubstitutionEnabled = false; # disable auto period substitution(智能句号替换)
        NSAutomaticQuoteSubstitutionEnabled = false; # disable auto quote substitution(智能引号替换)
        NSAutomaticSpellingCorrectionEnabled = false; # disable auto spelling correction(自动拼写检查)
        NSNavPanelExpandedStateForSaveMode = true; # expand save panel by default(保存文件时的路径选择/文件名输入页)
        NSNavPanelExpandedStateForSaveMode2 = true;
      };

      # Customize settings that not supported by nix-darwin directly
      # see the source code of this project to get more undocumented options:
      #    https://github.com/rgcr/m-cli
      # 
      # All custom entries can be found by running `defaults read` command.
      # or `defaults read xxx` to read a specific domain.
      CustomUserPreferences = {
        ".GlobalPreferences" = {
          # automatically switch to a new space when switching to the application
          AppleSpacesSwitchOnActivate = true;
        };
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
        };
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = false;
          ShowHardDrivesOnDesktop = false;
          ShowMountedServersOnDesktop = false;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          # When performing a search, search the current folder by default
          FXDefaultSearchScope = "SCcf";
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.screensaver" = {
          # Require password immediately after sleep or screen saver begins
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
        "com.apple.screencapture" = {
          location = "~/Desktop";
          type = "png";
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = true;
        };
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
      };

      loginwindow = {
        GuestEnabled = false; # disable guest user
        SHOWFULLNAME = true; # show full name in login window
      };
    };

    # use karabiner elements instead, this is hacky
    # keyboard settings is not very useful on macOS
    # the most important thing is to remap option key to alt key globally,
    # but it's not supported by macOS yet.
    # keyboard = {
    # enableKeyMapping = true;  # enable key mapping so that we can use `option` as `control`

    # NOTE: do NOT support remap capslock to both control and escape at the same time
    # remapCapsLockToControl = false;  # remap caps lock to control, useful for emac users
    # remapCapsLockToEscape  = true;   # remap caps lock to escape, useful for vim users

    # swap left command and left alt 
    # so it matches common keyboard layout: `ctrl | command | alt`
    #
    # disabled, caused only problems!
    # swapLeftCommandAndLeftAlt = false;  
    # };
  };

}

