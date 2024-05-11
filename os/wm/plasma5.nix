{ username, ... }: { pkgs, ... }:
let
  # References: https://github.com/brianIcke/nixos-conf/blob/226c97d1b78a527eb0126a7012e27d935d4b4da0/system/BrianTUX/pkgs/wallpaper-engine-plasma-plugin.nix#L37
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
    version = "91d8e25c0c94b4919f3d110c1f22727932240b3c";
    src = fetchFromGitHub {
      owner = "Jelgnum";
      repo = "wallpaper-engine-kde-plugin";
      rev = version;
      hash = "sha256-ff3U/TXr9umQeVHiqfEy38Wau5rJuMeJ3G/CZ9VE++g=";
      fetchSubmodules = true;
    };
    nativeBuildInputs = [
      cmake
      extra-cmake-modules
      glslang-submodule
      pkg-config
      gst_all_1.gst-libav
      shaderc
    ];
    buildInputs = [
      mpv
      lz4
      vulkan-headers
      vulkan-tools
      vulkan-loader
    ]
    ++ (with libsForQt5; with qt5; [ plasma-framework qtwebsockets qtwebchannel qtx11extras qtdeclarative ])
    ++ [ (python3.withPackages (python-pkgs: [ python-pkgs.websockets ])) ];
    cmakeFlags = [ "-DUSE_PLASMAPKG=OFF" ];
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
  };
  jetbrains-runner = with pkgs; stdenv.mkDerivation rec {
    pname = "jetbrains-runner";
    version = "63d6eae65a80e9969e8f613c9466e32b44b90524";
    src = fetchFromGitHub {
      owner = "alex1701c";
      repo = "JetBrainsRunner";
      rev = version;
      hash = "sha256-KhcxkFNdHpWEs+WGZMhWP1dQZOqp5q49u4/Ez+ahwbM=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [ cmake extra-cmake-modules pkg-config ];
    buildInputs = with libsForQt5; with qt5; [
      plasma-framework
      kcmutils
      kio
      krunner
    ] ++ [ libnotify ];
    dontWrapQtApps = true;

    meta = with lib; {
      description = "A Krunner Plugin which allows you to open your recent projects";
      homepage = "https://github.com/alex1701c/JetBrainsRunner";
      license = licenses.lgpl3;
      platforms = platforms.linux;
    };
  };
  jetbrains-dolphin = with pkgs; stdenv.mkDerivation rec {
    pname = "jetbrains-dolphin";
    version = "1.3.0";
    src = fetchFromGitHub {
      owner = "alex1701c";
      repo = "JetBrainsDolphinPlugin";
      rev = version;
      hash = "sha256-AqBqUfWyZN0iqTXy7hLHAtoV+N4HCv9+AGKsqnv1fGM=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [ cmake extra-cmake-modules ];
    buildInputs = with libsForQt5; with qt5; [ kio ];
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
  # Enable the X11 windowing system.
  services = {
    # Enable the KDE Plasma Desktop Environment.
    xserver.desktopManager.plasma5.enable = true;
    displayManager.sddm.enable = true;
  };
  environment.systemPackages = with pkgs; with libsForQt5; [
    latte-dock
    kdePackages.discover
    kdePackages.kgpg
    applet-window-buttons
    yakuake
    xclip
    jetbrains-runner
    jetbrains-dolphin
    ### wallpaper-engine-plugin
    wallpaper-engine-kde-plugin
    qt5.qtwebsockets
    (python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))
    ### 
  ];
  system.activationScripts = {
    wallpaper-engine-kde-plugin.text = ''
      wallpapers=share/plasma/wallpapers
      wallpaperenginetarget=$wallpapers/com.github.casout.wallpaperEngineKde
      mkdir -p /home/${username}/.local/$wallpapers
      homepath=/home/${username}/.local/$wallpaperenginetarget
      rm -f $homepath
      ln -fs ${wallpaper-engine-kde-plugin}/$wallpaperenginetarget $homepath
    '';
  };
  programs.partition-manager.enable = true;
}
