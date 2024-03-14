{
  imports = [
    ./dev
    ./nvim
    ./alternative.nix
    ./direenv.nix
    ./git.nix
    ./gpg.nix
    ./mise.nix
    ./util.nix
  ];
  # https://github.com/nix-community/home-manager/issues/355#issuecomment-524042996
  systemd.user.startServices = true;
}
