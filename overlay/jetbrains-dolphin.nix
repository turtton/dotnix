gen: self: prev: {
  jetbrains-dolphin = with self; stdenv.mkDerivation rec {
    inherit (gen) pname version src;

    nativeBuildInputs = [ cmake kdePackages.extra-cmake-modules ];
    buildInputs = with kdePackages; [ kio ];
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
