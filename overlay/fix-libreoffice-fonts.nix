# LibreOffice embeds noto-fonts, noto-fonts-lgc-plus, and noto-fonts-cjk-sans
# into its fontsConf (FONTCONFIG_FILE env var in the derivation).
# Replacing those packages via overlay changes LibreOffice's derivation hash,
# causing a cache miss and a full local rebuild every time.
# This overlay explicitly pins LibreOffice to use the upstream nixpkgs
# versions of those fonts, keeping its hash identical to cache.nixos.org.
# NOTE: This overlay must be applied BEFORE the noto-fonts-* overlays.
#
# Architecture note (nixpkgs all-packages.nix):
#   libreoffice-still = callPackage wrapper.nix { unwrapped = callPackage libreoffice { variant="still"; }; }
#   libreoffice-still-unwrapped = pkgs.libreoffice-still.unwrapped   ← refers to FINAL pkgs
#
# Cycle avoidance:
#   Using prev.libreoffice-still-unwrapped would create an infinite loop because in nixpkgs
#   it is defined as pkgs.libreoffice-still.unwrapped (using FINAL pkgs), which would
#   circularly reference our own overridden libreoffice-still.
#   Instead, we access prev.libreoffice-still.unwrapped directly (the wrapper's passthru,
#   whose value comes from the wrapper's own internal callPackage, not from the pkgs
#   fixed-point lookup of libreoffice-still-unwrapped).
self: prev:
let
  # noto-fonts, noto-fonts-lgc-plus, and noto-fonts-cjk-sans are function arguments
  # of the *-unwrapped derivation (see pkgs/applications/office/libreoffice/default.nix).
  # Using prev.* here (= this overlay's preceding package set, i.e. before our custom
  # noto-fonts-* overlays are applied) keeps the derivation hash identical to cache.nixos.org.
  fixFonts =
    pkg:
    pkg.override {
      noto-fonts = prev.noto-fonts;
      noto-fonts-lgc-plus = prev.noto-fonts-lgc-plus;
      noto-fonts-cjk-sans = prev.noto-fonts-cjk-sans;
    };

  # Access the wrapper's own internal .unwrapped passthru (NOT prev.libreoffice-still-unwrapped,
  # which uses the FINAL pkgs fixed-point and would create infinite recursion when we
  # also override libreoffice-still below).
  fixedStillUnwrapped = fixFonts prev.libreoffice-still.unwrapped;
  fixedFreshUnwrapped = fixFonts prev.libreoffice-fresh.unwrapped;
in
{
  # Expose the font-pinned unwrapped derivations at the expected attribute names.
  libreoffice-still-unwrapped = fixedStillUnwrapped;
  libreoffice-fresh-unwrapped = fixedFreshUnwrapped;

  # Fix the wrapper packages: each wrapper embeds the unwrapped path in its buildCommand,
  # so we must point them to the font-pinned unwrapped derivations above.
  libreoffice-still = prev.libreoffice-still.override {
    unwrapped = fixedStillUnwrapped;
  };
  libreoffice-fresh = prev.libreoffice-fresh.override {
    unwrapped = fixedFreshUnwrapped;
  };
}
