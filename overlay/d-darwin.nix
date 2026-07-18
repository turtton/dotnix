# Reference: https://github.com/colonelpanic8/dotfiles/blob/4e3e75c3e27372f3b7694fc3239bff6013d64ed9/nixos/overlay.nix
{ pkgs, inputs, ... }:
let
  generated = pkgs.callPackage ../_sources/generated.nix { };
in
{
  nixpkgs.overlays = [
    (import ./app-replacements.nix inputs)
    inputs.nix-vscode-extensions.overlays.default
    inputs.rust-overlay.overlays.default
    inputs.rustowl.overlays.default
    inputs.llm-agents.overlays.shared-nixpkgs
    (import ./claude-code inputs)
    (import ./codex)
    (import ./opencode inputs)
    (final: prev: {
      cnowledje = inputs.cnowledje.packages."${pkgs.system}".default;
      # https://github.com/NixOS/nixpkgs/issues/536623
      pnpm_10_29_2 = final.pnpm_10;
      # dreamac の Digital Guardian (dgagent/dgesc) が EndpointSecurity で
      # ファイル read を横取りし、undmg 展開直後のファイルを分類中だと open() が
      # 一時的に EPERM ("Operation not permitted") を返す。このため upstream の
      # installPhase の cp が同梱アセット (rust-rover の rust-*.zip 等) で非決定的に
      # 失敗する。全 JetBrains darwin 製品が同じ builder/installPhase パターン
      # (builder/darwin.nix, cp -Tr *.app) を共有しているため rust-rover 個別ではなく
      # jetbrains.* 全体に適用する。権限問題ではないので chmod では直らない。
      # install 前に全ファイルを読めるようになるまで待つ(=DG に分類を完了させる)。
      jetbrains = prev.lib.mapAttrs (
        _name: pkg:
        if prev.lib.isDerivation pkg then
          pkg.overrideAttrs (old: {
            preInstall = (old.preInstall or "") + ''
              for attempt in $(seq 1 30); do
                if find . -type f -print0 \
                     | xargs -0 -n1 sh -c 'exec cat "$0" >/dev/null'; then
                  echo "all files readable after $attempt attempt(s)"
                  break
                fi
                echo "attempt $attempt: files still held by Digital Guardian, retrying..."
                sleep 2
              done
            '';
          })
        else
          pkg
      ) prev.jetbrains;
    })
  ];
}
