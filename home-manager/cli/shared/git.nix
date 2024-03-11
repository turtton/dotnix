{pkgs, ...}: {
  programs.git = {
    enable = true;
    userName = "turtton";
    userEmail = "top.gear7509@turtton.net";
    signing = {
      key = "8152FC5D0B5A76E1";
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
        editor = "kate";
      };
      pack = {
        windowMemory = "2g";
        packSizeLimit = "1g";
      };
    };
  };
  programs.gh = {
    enable = true;
    extensions = with pkgs; [gh-markdown-preview];
    settings = {
      editor = "nvim";
    };
  };
  home.packages = with pkgs; [
    lazygit
  ];
}