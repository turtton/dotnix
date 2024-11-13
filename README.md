# dotnix

My dotfiles for NixOS

# [Hyprland](./home-manager/wm/hyprland/)

![](./docs/hypr.png)
- Bar: [Hyprpanel](https://hyprpanel.com)
- Editor: [Neovim](https://github.com/turtton/myvim.nix)
- Terminal: [Alacritty](https://alacritty.org)
- LockScreen: [HyprLock](https://github.com/hyprwm/hyprlock/)
- ScreenShot: [Grimblast+swappy](https://github.com/turtton/dotnix/blob/8186fca772bfa4d22db9263a04c08541cfbeafa9/home-manager/wm/hyprland/key-bindings.nix#L102-L106)

# Setup

1. Modify `/etc/nixos/configuration.nix`
   ```diff
   programs = {
   + git.enable = true;
   };
   + nix.settings.experimental-features = ["nix-command" "flakes"];
   ```

2. Run `sudo nixos-rebuild switch`

3. Clone this repository and move it

4. Run`nix develop`

5. Run `switch-nixos {name}`(or `sudo nixos-rebuild switch --flake .#{name}`)  
   Name: `virtbox` `maindesk` `bridgetop`

6. ~~Run `nix run nixpkgs#home-manager -- switch --flake .#{name}`(`switch-home {name}`)~~  

   > This method no longer needed, but settings still here to configure darwin system in the future.

7. Reboot

# References

> My environement log(JP):  
> https://zenn.dev/watagame/scraps/e64841d674d16e

- https://zenn.dev/asa1984/articles/nixos-is-the-best
- https://github.com/asa1984/dotfiles/blob/main

- https://nixos.wiki/wiki/
- https://search.nixos.org/packages
- https://mipmip.github.io/home-manager-option-search/

Hyprland themes:

- https://github.com/MrVivekRajan/Hypr-Dots/tree/Type-2?tab=readme-ov-file#spring-city
- (waybar) https://github.com/redyf/nixdots/tree/main/home/desktop/addons/waybar/tokyonight
