# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  ghr = {
    pname = "ghr";
    version = "v0.4.4";
    src = fetchFromGitHub {
      owner = "siketyan";
      repo = "ghr";
      rev = "v0.4.4";
      fetchSubmodules = false;
      sha256 = "sha256-L9+rcdt+MGZSCOJyCE4t/TT6Fjtxvfr9LBJYyRrx208=";
    };
  };
  hyprpanel-tokyonight = {
    pname = "hyprpanel-tokyonight";
    version = "e71a2dfe2dc0418d53841f0831ce7425d9f402e1";
    src = fetchFromGitHub {
      owner = "Jas-SinghFSU";
      repo = "HyprPanel";
      rev = "e71a2dfe2dc0418d53841f0831ce7425d9f402e1";
      fetchSubmodules = false;
      sha256 = "sha256-Nuy9PsojpPgezPY6+mjkt1bp+PqKADcjT4iEwqygs3U=";
    };
    "themes/tokyo_night.json" = builtins.readFile ./hyprpanel-tokyonight-e71a2dfe2dc0418d53841f0831ce7425d9f402e1/themes/tokyo_night.json;
    date = "2024-11-12";
  };
  jetbrains-dolphin = {
    pname = "jetbrains-dolphin";
    version = "1.4.2";
    src = fetchFromGitHub {
      owner = "alex1701c";
      repo = "JetBrainsDolphinPlugin";
      rev = "1.4.2";
      fetchSubmodules = true;
      sha256 = "sha256-T8ueCqYIKDRo4Ds/o0dCeNjK3dD8fNT9oNEDfzqLg0Y=";
    };
  };
  jetbrains-nautilus = {
    pname = "jetbrains-nautilus";
    version = "c79f6ab6504bd1f1a9d1068f284c24f3227f51c1";
    src = fetchFromGitHub {
      owner = "encounter";
      repo = "jetbrains-nautilus";
      rev = "c79f6ab6504bd1f1a9d1068f284c24f3227f51c1";
      fetchSubmodules = false;
      sha256 = "sha256-f78dMegKVe2fed5I0ogiaG+s9DkSF13s59fhhTr5U5c=";
    };
    date = "2021-05-17";
  };
  wallpaper-springcity = {
    pname = "wallpaper-springcity";
    version = "Golden-hour-latest";
    src = fetchurl {
      url = "https://raw.githubusercontent.com/MrVivekRajan/Hypr-Dots/refs/heads/Type-2/Spring-City/.config/swww/wall.png";
      sha256 = "sha256-mpsBjyOWLkITiGqHEWHQJacqrNvOaUSm7We5QOiDiww=";
    };
  };
}
