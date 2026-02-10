{ pkgs, inputs, ... }:
{
  programs.nix-ld = {
    enable = true;
    # From https://github.com/NixOS/nixpkgs/issues/240444#issuecomment-1988645885
    # I am not using jetbrains-toobox but these libraries useful to avoid probrems like this (https://discourse.nixos.org/t/issues-with-opengl-in-minecraft-development-environments/37532)
    libraries = with pkgs; [
      desktop-file-utils
      libxcomposite
      libxtst
      libxrandr
      libxext
      libx11
      libxfixes
      libGL

      gst_all_1.gstreamer
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-plugins-base
      libdrm
      xkeyboard-config
      libpciaccess

      glib
      gtk2
      bzip2
      zlib
      gdk-pixbuf

      libxinerama
      libxdamage
      libxcursor
      libxrender
      libxscrnsaver
      libxxf86vm
      libxi
      libsm
      libice
      freetype
      curlWithGnuTls
      nspr
      nss
      fontconfig
      cairo
      pango
      expat
      dbus
      cups
      libcap
      SDL2
      libusb1
      udev
      dbus-glib
      atk
      at-spi2-atk
      libudev0-shim

      libxt
      libxmu
      libxcb
      libxcb-util
      libxcb-wm
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libGLU
      libuuid
      libogg
      libvorbis
      SDL
      SDL2_image
      glew110
      openssl
      libidn
      tbb
      wayland
      mesa
      libxkbcommon
      vulkan-loader

      flac
      freeglut
      libjpeg
      libpng12
      libpulseaudio
      libsamplerate
      libmikmod
      libthai
      libtheora
      libtiff
      pixman
      speex
      SDL_image
      SDL_mixer
      SDL2_ttf
      SDL2_mixer
      libappindicator-gtk2
      libcaca
      libcanberra
      libgcrypt
      libvpx
      librsvg
      libxft
      libvdpau
      alsa-lib

      harfbuzz
      e2fsprogs
      libgpg-error
      keyutils.lib
      libjack2
      fribidi
      p11-kit

      gmp

      # used by hyprpanel
      libgtop

      # libraries not on the upstream include list, but nevertheless expected
      # by at least one appimage
      libtool.lib # for Synfigstudio
      libxshmfence # for apple-music-electron
      at-spi2-core
      pciutils # for FreeCAD
      pipewire # immersed-vr wayland support
    ];
  };
}
