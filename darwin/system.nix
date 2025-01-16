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
      enableKeyMapping = true;
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
  security.pam.enableSudoTouchIdAuth = true;
}
