{
  pkgs,
  lib,
  hostPlatform,
  config,
  ...
}:
let
  omoPatchFile = ../../../overlay/opencode/patches/oh-my-opencode-3.12.3.patch;
  omoPatchVersion = "3.12.3";
in
{
  home.packages =
    with pkgs;
    [
      codex-latest
      opencode-latest
      llm-agents.codex
      opencode
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
    ];
  programs.claude-code = {
    enable = true;
  };

  # oh-my-opencode のパッチ自動適用:
  # noReply: !allComplete → noReply: true に変更して
  # バックグラウンドタスク完了時の余分なLLMターン（Premium Request消費）を防ぐ
  home.activation.applyOmoPatch = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    OPENCODE_CACHE="$HOME/.cache/opencode"
    PATCH_DEST="$OPENCODE_CACHE/patches/oh-my-opencode@${omoPatchVersion}.patch"
    PACKAGE_JSON="$OPENCODE_CACHE/package.json"
    INDEX_JS="$OPENCODE_CACHE/node_modules/oh-my-opencode/dist/index.js"
    OHO_PKG_JSON="$OPENCODE_CACHE/node_modules/oh-my-opencode/package.json"

    # OpenCodeのキャッシュが存在し、パッチが未適用（!allComplete が残っている）場合のみ適用
    if [ -d "$OPENCODE_CACHE" ] && [ -f "$INDEX_JS" ] && grep -q "noReply: !allComplete" "$INDEX_JS"; then

      # インストール済みバージョンを確認（バージョン不一致の場合はスキップ）
      INSTALLED_VER="$(${pkgs.jq}/bin/jq -r '.version // empty' "$OHO_PKG_JSON" 2>/dev/null)"
      if [ "$INSTALLED_VER" != "${omoPatchVersion}" ]; then
        echo "oh-my-opencode noReply patch: skipping (installed: $INSTALLED_VER, patch targets: ${omoPatchVersion})"
      else
        echo "Applying oh-my-opencode noReply patch..."

        # パッチファイルをコピー
        mkdir -p "$OPENCODE_CACHE/patches"
        cp ${omoPatchFile} "$PATCH_DEST"

        # package.json に patchedDependencies を追記
        if [ -f "$PACKAGE_JSON" ]; then
          ${pkgs.jq}/bin/jq \
            --arg version "${omoPatchVersion}" \
            --arg patchPath "patches/oh-my-opencode@${omoPatchVersion}.patch" \
            '.patchedDependencies["oh-my-opencode@\($version)"] = $patchPath' \
            "$PACKAGE_JSON" > "$PACKAGE_JSON.tmp" && mv "$PACKAGE_JSON.tmp" "$PACKAGE_JSON"
        fi

        # bun install でパッチを適用（--silent で通常出力は抑制しつつ、stderrは表示）
        ${pkgs.bun}/bin/bun install --cwd "$OPENCODE_CACHE" --silent

        # パッチ適用確認
        if grep -q "noReply: !allComplete" "$INDEX_JS"; then
          echo "WARNING: oh-my-opencode noReply patch may not have applied correctly"
        else
          echo "oh-my-opencode noReply patch applied successfully."
        fi
      fi
    fi
  '';
}
