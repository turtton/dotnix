gen: self: prev: {
  jetbrains-nautilus = with self; stdenv.mkDerivation {
    inherit (gen) pname version src;

    installPhase = ''
            			install -Dm755 $src/jetbrains-nautilus.py $out/share/nautilus-python/extensions/jetbrains-nautilus.py
      						install -Dm644 $src/LICENSE $out/share/licenses/jetbrains-nautilus/LICENSE
            		'';

    meta = with lib; {
      description = "Nautilus extension to open folder in JetBrains IDEs";
      homepage = "https://github.com/encounter/jetbrains-nautilus";
      license = licenses.unlicense;
    };
  };
}
