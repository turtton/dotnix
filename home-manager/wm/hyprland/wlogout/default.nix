{ pkgs, ... }: {
	home.packages = [ pkgs.wlogout pkgs.envsubst pkgs.bc ];
	xdg.configFile.wlogout = {
		source = ./config;
		recursive = true;
	};
}
