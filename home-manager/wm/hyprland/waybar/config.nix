{ pkgs, ... }:
{
  mainBar = {
    margin-top = 6;
    margin-bottom = 2;
    margin-right = 8;
    margin-left = 8;
    modules-left = [
      "hyprland/workspaces"
      "hyprland/window"
    ];
    modules-center = [
      "custom/media"
    ];
    modules-right = [
      "battery"
      "cpu"
      "memory"
      # "backlight"
      "pulseaudio"
      "bluetooth"
      "network"
      "tray"
      "clock"
      "custom/notification"
    ];
    output = [
      "eDP-1"
      "DP-1"
    ];

    "hyprland/workspaces" = {
      active-only = "false";
      on-scroll-up = "hyprctl dispatch  split-cycleworkspaces +1";
      on-scroll-down = "hyprctl dispatch split-cycleworkspaces -1";
      disable-scroll = "false";
      all-outputs = "false";
      format = "{icon}";
      on-click = "activate";
      format-icons = {
        "urgent" = "";
        "active" = "";
        "visible" = "";
        "default" = "";
        "empty" = "";
      };
    };
    "hyprland/window" = {
      format = "{initialTitle}";
    };

    "custom/media" = {
      "format" = "  {}";
      "max-lenght" = "40";
      "interval" = "1";
      "exec" = "playerctl metadata --format '{{ artist }} - {{ title }}'";
      "on-click" = "playerctl play-pause";
      "on-click-right" = "playerctl stop";
      "smooth-scrolling-threshold" = "4";
      "on-scroll-up" = "playerctl next";
      "on-scroll-down" = "playerctl previous";
    };

    "idle_inhibitor" = {
      format = "{icon}";
      format-icons = {
        activated = " ";
        deactivated = " ";
      };
    };

    "tray" = {
      spacing = "10";
    };

    "clock" = {
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      format = " {:%H:%M}";
      format-alt = "󰃰 {:%A, %B %d, %Y}";
    };

    "cpu" = {
      format = " {usage}%";
      tooltip = "false";
    };

    "memory" = {
      format = " {}%";
      on-click = "foot -e btop";
    };

    "backlight" = {
      format = "{icon}{percent}%";
      format-icons = [
        "󰃞 "
        "󰃟 "
        "󰃠 "
      ];
      on-scroll-up = "light -A 1";
      on-scroll-down = "light -U 1";
    };

    "battery" = {
      states = {
        warning = "30";
        critical = "15";
      };
      format = "{icon}{capacity}%";
      tooltip-format = "{timeTo} {capacity}%";
      format-charging = "󰂄 {capacity}%";
      format-plugged = " ";
      format-alt = "{time} {icon}";
      format-icons = [
        "  "
        "  "
        "  "
        "  "
        "  "
      ];
    };

    "bluetooth" = {
      # "controller" =  "controller1";  # specify the alias of the controller if there are more than 1 on the system
      "format" = " {status}";
      "format-disabled" = ""; # an empty format will hide the module
      "format-connected" = " {num_connections} connected";
      "tooltip-format" = "{controller_alias}\t{controller_address}";
      "tooltip-format-connected" = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
      "tooltip-format-enumerate-connected" = "{device_alias}\t{device_address}";
    };

    "network" = {
      format-wifi = "󰖩 {essid}";
      # format-ethernet = "{ifname}: {ipaddr}/{cidr} 󰈀 ";
      format-ethernet = "󰈀 {cidr}";
      format-linked = "{ifname} (No IP) 󰈀 ";
      format-disconnected = "󰖪  Disconnected";
      # on-click = "$HOME/.config/hypr/Scripts/wifi-menu";
      on-click = "foot -e nmtui";
      tooltip-format = "{essid} {signalStrength}%";
    };

    "pulseaudio" = {
      format = "{icon}{volume}%";
      format-bluetooth = "{icon} {volume}%";
      format-bluetooth-muted = "   {volume}%";
      format-muted = "  {format_source}";
      format-icons = {
        headphone = " ";
        hands-free = "󰂑 ";
        headset = "󰂑 ";
        phone = " ";
        portable = " ";
        car = " ";
        default = [
          " "
          " "
          " "
        ];
      };
      tooltip-format = "{desc} {volume}%";
      on-click = "${pkgs.pavucontrol}/bin/pavucontrol -t 3";
    };

    "custom/notification" = {
      "tooltip" = false;
      "format" = "{icon}<span><sup>{0}</sup></span>";
      "format-icons" = {
        "notification" = "󱅫";
        "none" = "󰂚";
        "dnd-notification" = "󰂛";
        "dnd-none" = "󰂛";
        "inhibited-notification" = "󱅫";
        "inhibited-none" = "󰂚";
        "dnd-inhibited-notification" = "󰂛";
        "dnd-inhibited-none" = "󰂛";
      };
      "return-type" = "json";
      "exec-if" = "which swaync-client";
      "exec" = "swaync-client -swb";
      "on-click" = "swaync-client -t -sw";
      "on-click-right" = "swaync-client -d -sw";
      "escape" = true;
    };
  };
}
