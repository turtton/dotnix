gen: self: prev:
let
  jetbrains-dolphin = { useQt6 }:
    let
      targetPackages = if useQt6 then self.kdePackages else self.libsForQt5;
    in
    with self; stdenv.mkDerivation {
      inherit (gen) pname version src;

      nativeBuildInputs = [ cmake targetPackages.extra-cmake-modules ];
      buildInputs = with targetPackages; [ kio ];
      cmakeFlags =
        if useQt6 then [
          "-DBUILD_WITH_QT6=ON"
        ] else [ ];
      dontWrapQtApps = true;
      meta = with lib; {
        description = "A Krunner Plugin which allows you to open your recent projects";
        homepage = "https://github.com/alex1701c/JetBrainsDolphinPlugin";
        license = licenses.gpl2;
        platforms = platforms.linux;
      };
    };
in
{
  jetbrains-dolphin-qt6 = jetbrains-dolphin { useQt6 = true; };
  jetbrains-dolphin-qt5 = jetbrains-dolphin { useQt6 = false; };
}
