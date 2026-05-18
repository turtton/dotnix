gen: self: prev: {
  jetbrains-dolphin =
    let
      targetPackages = self.kdePackages;
    in
    with self;
    stdenv.mkDerivation {
      inherit (gen) pname version src;

      nativeBuildInputs = [
        cmake
        targetPackages.extra-cmake-modules
      ];
      buildInputs = with targetPackages; [ kio ];
      cmakeFlags = [
        "-DBUILD_WITH_QT6=ON"
      ];
      dontWrapQtApps = true;
      meta = with lib; {
        description = "A Krunner Plugin which allows you to open your recent projects";
        homepage = "https://github.com/alex1701c/JetBrainsDolphinPlugin";
        license = licenses.gpl2;
        platforms = platforms.linux;
      };
    };

}
