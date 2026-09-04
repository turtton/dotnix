let
  hk = binding: id: { inherit binding id; };

  workspaceBinds = builtins.concatLists (
    builtins.genList (
      i:
      let
        n = toString (i + 1);
        w = toString i;
      in
      [
        (hk "Option+${n}" "switchWorkspace.${w}")
        (hk "Option+Shift+${n}" "moveColumnToWorkspace.${w}")
        (hk "Control+Option+Shift+${n}" "moveToWorkspace.${w}")
        (hk "Control+Option+${n}" "focusColumn.${w}")
      ]
    ) 9
  );
in
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

  workspaceBar.enabled = true;

  statusBar = {
    showWorkspaceName = true;
    useWorkspaceId = true;
    showAppNames = false;
  };

  # niri 寄せ: Option=フォーカス、+Shift=移動、Control+Option=ワークスペース/サイズ。
  # OmniWM は 1 action = 1 バインド / 1 キー = 1 action しか許さない (duplicateRegistryId,
  # duplicateBinding で登録が落ちる)。niri のように hjkl と矢印を同じ action へ二重登録できないため、
  # hjkl には粒度の細かい action、矢印には対になる汎用 action を割り当てている。
  hotkeys = workspaceBinds ++ [
    (hk "Option+H" "focus.left")
    (hk "Option+J" "focus.down")
    (hk "Option+K" "focus.up")
    (hk "Option+L" "focus.right")

    (hk "Option+Shift+H" "moveColumn.left")
    (hk "Option+Shift+L" "moveColumn.right")
    (hk "Option+Shift+J" "moveWindowDown")
    (hk "Option+Shift+K" "moveWindowUp")
    (hk "Option+Shift+Left Arrow" "move.left")
    (hk "Option+Shift+Right Arrow" "move.right")
    (hk "Option+Shift+Down Arrow" "move.down")
    (hk "Option+Shift+Up Arrow" "move.up")

    (hk "Control+Option+J" "switchWorkspace.next")
    (hk "Control+Option+K" "switchWorkspace.previous")
    (hk "Option+Grave" "workspaceBackAndForth")
    (hk "Control+Option+Shift+J" "moveColumnToWorkspaceDown")
    (hk "Control+Option+Shift+K" "moveColumnToWorkspaceUp")
    (hk "Control+Option+Shift+Down Arrow" "moveWindowToWorkspaceDown")
    (hk "Control+Option+Shift+Up Arrow" "moveWindowToWorkspaceUp")

    (hk "Control+Option+H" "setContainerPrimarySpan.decrease10Percent")
    (hk "Control+Option+L" "setContainerPrimarySpan.increase10Percent")
    (hk "Control+Option+Left Arrow" "setWindowPrimarySpan.decrease10Percent")
    (hk "Control+Option+Right Arrow" "setWindowPrimarySpan.increase10Percent")
    (hk "Control+Option+F" "expandContainerToAvailablePrimarySpan")
    (hk "Option+Shift+Minus" "setWindowSecondarySpan.decrease10Percent")
    (hk "Option+Shift+Equal" "setWindowSecondarySpan.increase10Percent")
    (hk "Option+Shift+B" "balanceSizes")
    (hk "Option+Period" "cycleSizeForward")
    (hk "Option+Comma" "cycleSizeBackward")

    (hk "Option+Left Bracket" "consumeWindowIntoColumn")
    (hk "Option+Right Bracket" "expelWindowFromColumn")
    (hk "Option+Shift+Left Bracket" "consumeOrExpelWindowLeft")
    (hk "Option+Shift+Right Bracket" "consumeOrExpelWindowRight")
    (hk "Option+Home" "focusColumnFirst")
    (hk "Option+End" "focusColumnLast")
    (hk "Control+Option+Home" "moveColumnToFirst")
    (hk "Control+Option+End" "moveColumnToLast")
    (hk "Option+T" "toggleColumnTabbed")

    (hk "Option+F" "toggleFullscreen")
    (hk "Option+Shift+F" "toggleFocusedWindowFloating")
    (hk "Option+Shift+R" "raiseAllFloatingWindows")
    (hk "Control+Option+R" "resetWindowSecondarySpan")

    (hk "Option+Tab" "toggleOverview")
    (hk "Option+Shift+Tab" "focusPrevious")
    (hk "Control+Option+Tab" "focusMonitorNext")
    (hk "Control+Option+Shift+Tab" "focusMonitorPrevious")
    (hk "Control+Command+Grave" "focusMonitorLast")

    (hk "Option+D" "openCommandPalette")
    (hk "Option+Return" "toggleQuakeTerminal")
    (hk "Control+Option+M" "openMenuAnywhere")
  ];
}
