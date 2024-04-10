{ userName, userEmail, signingKey ? "", }:
{ pkgs, ... }: {
  programs.git = {
    enable = true;
    inherit userName userEmail;
    signing = {
      key = signingKey;
      signByDefault = true;
    };
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        line-numbers = true;
      };
    };
    extraConfig = {
      init.defaultBranch = "main";
      core = {
        autocrlf = "input";
        editor = "nvim";
      };
      pack = {
        windowMemory = "2g";
        packSizeLimit = "1g";
      };
    };
  };
  programs.gh = {
    enable = true;
    extensions = with pkgs; [ gh-markdown-preview ];
    settings = {
      editor = "nvim";
    };
  };
  home.packages = with pkgs; [
    lazygit
    gitmoji-cli
  ];
}
