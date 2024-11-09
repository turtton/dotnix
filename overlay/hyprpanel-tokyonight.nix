gen: self: prev: {
  hyprpanel-tokyonight = with self; stdenv.mkDerivation {
    inherit (gen) pname version src;

    dontUnpack = true;

    installPhase = ''
      			mkdir -p $out
      			cp $src $out/tokyo_night.json
      		'';

    meta = with lib; {
      description = "Tokyonight colorscheme for HyprPanel";
      homepage = "https://github.com/Jas-SinghFSU/HyprPanel/blob/master/themes/tokyo_night.json";
      license = with licenses; [ mit ];
    };
  };
}
