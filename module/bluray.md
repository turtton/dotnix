# Blu-ray playback

Host `maindesk` enables `packs.bluray.enable = true` ([bluray.nix](./bluray.nix)). The pack:

- loads the `sg` kernel module
- adds users to the `cdrom` group
- installs `libbluray` (`bd_info`, `bd_list_titles`) and `makemkv`
- sets session env vars `LIBAACS_PATH` / `LIBBDPLUS_PATH` / `MAKEMKVCON` pointing at MakeMKV's `libmmbd`

With those vars set, plain `mpv` decrypts commercial Blu-rays through libbluray's dlopen hook. No KEYDB.cfg needed for mpv.

## Playing

Insert a disc, then:

```sh
mpv bd://           # longest title
mpv bd://3          # specific title
bd_list_titles /dev/sr1
```

Examples use `/dev/sr1` (the second optical drive here). Substitute your actual device, or pass it explicitly with `--bluray-device=/dev/sr1`. The env vars are set at session level, so anything launched after login (terminal, app launcher) just works.

## VLC

VLC does NOT use the MakeMKV backend. nixpkgs vlc links `libbluray-full`, which hardcodes nixpkgs libaacs/libbdplus and ignores the env vars. VLC therefore needs a KEYDB.cfg.

Download the public VUK database from `https://fvonline-db.bplaced.net/fv_download.php?lang=eng` (the old `keydb_eng.zip` URL is dead). The zip contains a single `keydb.cfg` (~65MB); the unzip listing shows its build date, which tells you the DB freshness. Place it at `~/.config/aacs/KEYDB.cfg` (filename case matters). KEYDB.cfg is never committed to this repo. When a newer disc fails with `AACS handled : no`, re-download and replace the file.

Verify without a GUI using the nixpkgs backend via inline env vars, expecting `AACS handled : yes`:

```sh
LIBAACS_PATH=<libaacs-store>/lib/libaacs LIBBDPLUS_PATH=<libbdplus-store>/lib/libbdplus bd_info /dev/sr1
```

Get the store paths from the repo with `nix eval --raw .#nixosConfigurations.maindesk.pkgs.libaacs.outPath` (same for libbdplus), then:

```sh
vlc bluray:///dev/sr1
```

The disc menu shows (HDMV menus work without Java; BD-J menus would need a JRE). VLC logs print `First play: 1, Top menu: 1` when the menu loads, a useful grep for headless debugging.

## Switching backend

Set `packs.bluray.backend = "libaacs"` in the host's sharedOptions to use libaacs/libbdplus instead. This requires KEYDB.cfg, and BD+ additionally needs vm0/convtab files which have no clean public source. The makemkv backend is the default for this reason.

## MakeMKV beta key

`libmmbd` requires a valid MakeMKV registration. The key lives in `~/.MakeMKV/settings.conf` as `app_Key = "T-..."`. The current beta key is posted by the developer at https://forum.makemkv.com/forum/viewtopic.php?f=5&t=1053 and expires roughly every 1-2 months. Symptom of expiry: `bd_info` shows `AACS handled : no` with `No usable AACS libraries found!` despite everything else being fine.

## Troubleshooting

| Check | Command / expected |
| --- | --- |
| sg module loaded | `lsmod \| grep ^sg` |
| device nodes | `ls -l /dev/sr1 /dev/sg*` (root:cdrom) |
| group membership | `id -nG` contains `cdrom` (re-login required after first enabling) |
| disc status | `bd_info /dev/sr1`: BluRay detected / AACS detected / AACS handled / BD+ handled |

`bd_info` needs the env vars. They are present in login sessions; from a bare shell set them inline:

```sh
LIBAACS_PATH=<makemkv-store-path>/lib/libmmbd LIBBDPLUS_PATH=<makemkv-store-path>/lib/libmmbd bd_info /dev/sr1
```
