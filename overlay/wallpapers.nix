gen: self: prev: {
  wallpaper-springcity =
    with self;
    stdenv.mkDerivation {
      inherit (gen) pname version src;

      dontUnpack = true;

      installPhase = ''
        mkdir -p $out
        cp $src $out/wall.png
      '';

      meta = with lib; {
        description = "Cool wallpaper theme spring city";
        homepage = "https://github.com/MrVivekRajan/Hypr-Dots/tree/Type-2?tab=readme-ov-file#spring-city";
        license = with licenses; [ gpl3 ];
      };
    };
  wallpaper-outerspace =
    with self;
    stdenv.mkDerivation (this: {
      name = "wallpaper-outerspace";
      version = "9de80fe0ed499c4a55b9530d2178eeb9b89d7e36";

      src = fetchurl {
        url = "https://raw.githubusercontent.com/aidanhopper/dotfiles/${this.version}/Pictures/nord/ign_outer_space.png";
        hash = "sha256-pJNaFTEJNw2C8G2c9woueQguMoLWIZ4EFzqH+IIOYTw=";
      };

      dontUnpack = true;

      installPhase = ''
        mkdir -p $out
        cp $src $out/wall.png
      '';

      meta = {
        description = "Cool wallpaper theme outer space";
        homepage = "https://github.com/aidanhopper/dotfiles/blob/${this.version}/Pictures/nord/ign_outer_space.png";
      };
    });
}
