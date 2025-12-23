{ ... }:
{
  programs.niri.settings = {
    binds = {
      "Mod+V".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "launcher"
        "clipboard"
      ];
      "Mod+d".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "launcher"
        "toggle"
      ];
      "Mod+Shift+d".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "launcher"
        "calculator"
      ];
    };
  };
}
