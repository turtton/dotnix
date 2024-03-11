# dotnix

My dotfiles for NixOS

# Setup

1. Modify `/etc/nixos/configuration.nix`
   ```diff
   programs = {
   + git = {
   +   enable = true
   + }
   }
   nix = {
     settings = {
   +   experimental-features = ["nix-command" "flakes"];
     }
   }
   ```

2. Run `sudo nixos-rebuild switch`

3. Clone this repository and move it folder

4. Run `sudo nixos-rebuild switch --flake .#{name}`
   Name: `virtbox`

5. Run `nix run nixpkgs#home-manager -- switch --flake .#{name}`
   Name: `turtton@virtbox`

6. Reboot

# References

Log: https://zenn.dev/watagame/scraps/e64841d674d16e

https://zenn.dev/asa1984/articles/nixos-is-the-best
https://github.com/asa1984/dotfiles/blob/main

https://nixos.wiki/wiki/
https://search.nixos.org/packages
https://mipmip.github.io/home-manager-option-search/

