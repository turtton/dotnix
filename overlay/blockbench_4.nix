inputs: self: prev:
let
  system = prev.stdenv.hostPlatform.system;
  pkgs-blockbench4 = import inputs.nixpkgs-blockbench4 { inherit system; };
  original = pkgs-blockbench4.blockbench;
in
{
  blockbench_4 = prev.symlinkJoin {
    name = "blockbench_4-${original.version}";
    paths = [ original ];
    nativeBuildInputs = [ prev.makeWrapper ];
    postBuild = ''
      # Replace binary: rename blockbench -> blockbench_4
      rm $out/bin/blockbench
      makeWrapper ${original}/bin/blockbench $out/bin/blockbench_4

      # Remove shared data dir to avoid conflicts with blockbench v5
      # (the original binary resolves its resources from its own store path)
      rm -rf $out/share/blockbench

      # Replace desktop entry with renamed exec, name, and icon
      rm -rf $out/share/applications
      mkdir -p $out/share/applications
      substitute ${original}/share/applications/blockbench.desktop \
        $out/share/applications/blockbench_4.desktop \
        --replace-fail "Exec=blockbench" "Exec=blockbench_4" \
        --replace-fail "Name=Blockbench" "Name=Blockbench 4" \
        --replace-fail "Icon=blockbench" "Icon=blockbench_4"

      # Rename icons to avoid conflicts with newer blockbench
      for dir in $out/share/icons/hicolor/*/apps; do
        if [ -L "$dir/blockbench.png" ]; then
          mv "$dir/blockbench.png" "$dir/blockbench_4.png"
        fi
      done
    '';
    meta = original.meta // {
      mainProgram = "blockbench_4";
    };
  };
}
