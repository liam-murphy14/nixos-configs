{ ... }:

{
  imports = [ ./gitall.nix ];
  programs.git = {
    enable = true;
    difftastic = {
      enable = true;
      background = "dark";
    };
    userEmail = "liam.murphy137@gmail.com";
    userName = "liam-murphy14";
  };
}
