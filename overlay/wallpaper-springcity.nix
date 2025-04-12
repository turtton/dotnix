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
}
