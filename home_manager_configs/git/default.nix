{ ... }:

{
  imports = [ ./gitall.nix ];
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "liam.murphy137@gmail.com";
        name = "liam-murphy14";
      };
    };
  };
  programs.difftastic = {
    enable = true;
    git = {
      enable = true;
    };
    options = {
      background = "dark";
    };
  };
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
}
