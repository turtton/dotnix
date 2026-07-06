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
    inputs.llm-agents.overlays.default
    (import ./claude-code inputs)
    (import ./codex)
    (import ./opencode inputs)
    (final: prev: {
      cnowledje = inputs.cnowledje.packages."${pkgs.system}".default;
      # https://github.com/NixOS/nixpkgs/issues/536623
      pnpm_10_29_2 = final.pnpm_10;
    })
  ];
}
