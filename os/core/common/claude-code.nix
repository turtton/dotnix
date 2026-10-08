{ ... }:
{
  environment.etc."claude-code/managed-settings.json".source =
    ../../../overlay/claude-code/sandbox-settings.json;
}
