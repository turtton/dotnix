{pkgs, ...} : let 
# References: https://github.com/brianIcke/nixos-conf/blob/226c97d1b78a527eb0126a7012e27d935d4b4da0/system/BrianTUX/pkgs/wallpaper-engine-plasma-plugin.nix#L37
# These build settings not work. Idk how to fix it.
# Error Qt6Qml cound not be found because dependency Qt6 cound not be found.
glslang-submodule = with pkgs; stdenv.mkDerivation {
  name = "glslang";
  installPhase = ''
    mkdir -p $out
  '';
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "glslang";
    rev = "c34bb3b6c55f6ab084124ad964be95a699700d34";
    sha256 = "IMROcny+b5CpmzEfvKBYDB0QYYvqC5bq3n1S4EQ6sXc=";
  };
};
wallpaper-engine-kde-plugin = with pkgs; stdenv.mkDerivation rec {
  pname = "wallpaperEngineKde";
  version = "96230de92f1715d3ccc5b9d50906e6a73812a00a";
  src = fetchFromGitHub {
    owner = "catsout";
    repo = "wallpaper-engine-kde-plugin";
    rev = version;
    hash = "sha256-vkWEGlDQpfJ3fAimJHZs+aX6dh/fLHSRy2tLEsgu/JU=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = with kdePackages; [
    cmake extra-cmake-modules glslang-submodule pkg-config gst_all_1.gst-libav shaderc ninja # qwrapQtAppsHook
  ];
  buildInputs = [
    mpv lz4 vulkan-headers vulkan-tools vulkan-loader
  ] 
  ++ (with kdePackages; with qt6Packages; [
    qtbase
    # plasma-sdk
    kpackage
    kdeclarative
    # libplasma
    # plasma-workspace
    # kde-dev-utils
    plasma5support
    qt5compat
    qtwebsockets
    qtwebengine
    qtwebchannel
    qtmultimedia
    qtdeclarative
  ])
  ++ [(python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))];
  cmakeFlags = [ "-DUSE_PLASMAPKG=OFF" ];#"-DCMAKE_BUILD_TYPE=Release" "-DBUILD_QML=ON" "-DQT_MAJOR_VERSION=6" ];
  dontWrapQtApps = true;
  postPatch = ''
    rm -rf src/backend_scene/third_party/glslang
    ln -s ${glslang-submodule.src} src/backend_scene/third_party/glslang
  '';
  #Optional informations
  meta = with lib; {
    description = "Wallpaper Engine KDE plasma plugin";
    homepage = "https://github.com/Jelgnum/wallpaper-engine-kde-plugin";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
  # Not work yet
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/applet-window-buttons/default.nix#L20
  applet-window-buttons6 = with pkgs; libsForQt5.applet-window-buttons.overrideAttrs(old: rec {
    version = "a7b95da32717b90a1d9478db429d6fa8a6c4605f";
    # https://github.com/moodyhunter/applet-window-buttons6
    src = fetchFromGitHub {
      owner = "moodyhunter";
      repo = "applet-window-buttons6";
      rev = version;
      # hash = "";
    };
    patches = [];
  });
};
in {
  # Enable the X11 windowing system.
  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;
    # Enable the KDE Plasma Desktop Environment.
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;
  };
  environment.systemPackages = with pkgs; with kdePackages; [
    discover
    kgpg
    yakuake
    applet-window-buttons6
    ### wallpaper-engine-plugin
    wallpaper-engine-kde-plugin
    qtwebsockets
    (python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))
    ###
  ];
}