# [[hotkeys]] は意図的に持たない。OmniWM 既定が Option 中心で旧 yabai と同型のため、
# バインドは GUI 側の管理に任せる。
{
  general = {
    defaultLayoutType = "niri";
    animationsEnabled = true;
    hotkeysEnabled = true;
    ipcEnabled = true;
    # /nix/store は read-only なので自己更新は失敗する
    updateChecksEnabled = false;
    preventSleepEnabled = false;
  };

  appearance.mode = "dark";

  gaps = {
    size = 5.0;
    outer = {
      top = 0.0;
      bottom = 0.0;
      left = 0.0;
      right = 0.0;
    };
  };

  # 枠はフォーカス中のウィンドウにのみ描かれる。inactive 色は存在しない
  borders = {
    enabled = true;
    width = 2.0;
    color = {
      red = 0.5098039215686274;
      green = 0.6666666666666666;
      blue = 1.0;
      alpha = 1.0;
    };
  };

  focus = {
    followsMouse = true;
    moveMouseToFocusedWindow = false;
    followsWindowToMonitor = false;
  };

  niri = {
    columnWidthPresets = [
      0.3333333333333333
      0.5
      0.6666666666666666
    ];
    visibleContainerCount = 2;
    singleWindowFit = "none";
    maxWindowsPerColumn = 10;
    centerFocusedColumn = "never";
    alwaysCenterSingleColumn = false;
    infiniteLoop = false;
  };

  gestures = {
    scrollEnabled = true;
    scrollModifierKey = "optionShift";
    scrollSensitivity = 5.0;
    mouseResizeModifierKey = "option";
    fingerCount = 3;
    invertDirection = true;
  };

  workspaceBar.enabled = false;

  statusBar = {
    showWorkspaceName = true;
    useWorkspaceId = true;
    showAppNames = false;
  };
}
