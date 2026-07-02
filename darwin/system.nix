{ pkgs, ... }:
let
  claudeManagedSettings = pkgs.writeText "claude-code-managed-settings.json" (
    builtins.toJSON {
      allowManagedPermissionRulesOnly = true;
      sandbox = {
        enabled = true;
        failIfUnavailable = true;
        autoAllowBashIfSandboxed = true;
        allowUnsandboxedCommands = false;
        excludedCommands = [ ];
        network = {
          allowUnixSockets = [ ];
          allowAllUnixSockets = false;
          allowLocalBinding = false;
          allowedDomains = [ ];
          httpProxyPort = null;
          socksProxyPort = null;
        };
        enableWeakerNestedSandbox = false;
      };
    }
  );
in
{
  system = {
    defaults = {
      CustomUserPreferences."com.apple.AppleMultitouchTrackpad".DragLock = true;
      dock = {
        autohide = true;
        largesize = 64;
        magnification = true;
        mineffect = "scale";
        show-recents = false;
        tilesize = 50;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      NSGlobalDomain = {
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
      trackpad = {
        Clicking = true;
        Dragging = true;
      };
    };
    keyboard = {
      # this settings changes not only laptop keyboard but also external keyboard
      enableKeyMapping = false;
      userKeyMapping =
        let
          leftFn = 1095216660483;
          leftControl = 30064771296;
          # alt key
          leftOption = 30064771298;
          leftCommand = 30064771299;
        in
        [
          {
            HIDKeyboardModifierMappingSrc = leftFn;
            HIDKeyboardModifierMappingDst = leftControl;
          }
          {
            HIDKeyboardModifierMappingSrc = leftControl;
            HIDKeyboardModifierMappingDst = leftCommand;
          }
          {
            HIDKeyboardModifierMappingSrc = leftCommand;
            HIDKeyboardModifierMappingDst = leftFn;
          }
        ];
    };
  };
  system.activationScripts.postActivation.text = ''
    install -d -m 0755 "/Library/Application Support/ClaudeCode"
    install -m 0644 "${claudeManagedSettings}" "/Library/Application Support/ClaudeCode/managed-settings.json"
  '';
  security.pam.services.sudo_local.touchIdAuth = true;
}
