{ pkgs, lib, inputs, ... }:
let
  nvim-project = inputs.turtton-neovim.packages.${pkgs.system};
in
{
	home = {
		packages = [ nvim-project.default ];
		sessionVariables.EDITOR = "nvim";
		file.".config/nvim" = {
		  source = nvim-project.config;
		  recursive = true;
		};
	};
}
