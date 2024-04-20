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

3. Clone this repository and move it

4. Run `sudo nixos-rebuild switch --flake .#{name}`(`switch-nixos {name}`)  
   Name: `virtbox` `maindesk` `bridgetop`

5. ~~Run `nix run nixpkgs#home-manager -- switch --flake .#{name}`(`switch-home {name}`)~~  
   
   > This method no longer needed, but settings still here to configure darwin system in the future.
   
6. Reboot

# References

> My environement log(JP):  
> https://zenn.dev/watagame/scraps/e64841d674d16e

- https://zenn.dev/asa1984/articles/nixos-is-the-best
- https://github.com/asa1984/dotfiles/blob/main

- https://nixos.wiki/wiki/
- https://search.nixos.org/packages
- https://mipmip.github.io/home-manager-option-search/

