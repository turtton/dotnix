{ pkgs, ... }: {
  home.packages = with pkgs; [
    nautilus
    nautilus-python
    nautilus-open-any-terminal
    jetbrains-nautilus
    sushi
    turtle
  ];
}
