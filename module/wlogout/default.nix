{
  pkgs,
  config,
  isHomeManager,
  inputs,
  system,
  lib,
  ...
}:
if isHomeManager then
  let
    noctalia-shell = lib.getExe inputs.noctalia.packages.${system}.default;
  in
  {
    programs.wlogout = {
      enable = config.packages.hyprland.enable or config.packs.niri.enable;
      style =
        let
          getPath = name: "${pkgs.wlogout}/share/wlogout/icons/${name}.png";
          rawCss = builtins.readFile ./wlogout.css;
          builtinTargets = [
            "shutdown"
            "reboot"
            "suspend"
            "hibernate"
            "lock"
            "logout"
          ];
          targetNames = builtinTargets ++ [ "win" ];
          targets = builtins.map (name: "@${name}@") targetNames;
          icons = builtins.map (name: getPath name) builtinTargets ++ [ "${./win.png}" ];
          # Replace the @target@ strings in the CSS with the corresponding icon paths
          css = builtins.replaceStrings targets icons rawCss;
        in
        css;
      layout = [
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "s";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "Reboot";
          keybind = "r";
        }
        {
          label = "suspend";
          action = "systemctl suspend";
          text = "Suspend";
          keybind = "u";
        }
        {
          label = "hibernate";
          action = "systemctl hibernate";
          text = "Hibernate";
          keybind = "h";
        }
        {
          label = "lock";
          action = "${noctalia-shell} ipc call lockScreen lock";
          text = "Lock";
          keybind = "l";
        }
        {
          label = "win";
          action = "${./bootwin.sh}";
          text = "Boot Windows";
          keybind = "w";
        }
      ];
    };
  }
else
  { }
