# tests/herdr/default.nix からも import されるため、flake inputs に依存させないこと。
{ writeText, writeShellScript }:
let
  mkQuotaPoller =
    name:
    writeText name (
      builtins.replaceStrings [ "__QUOTA_REPORT__" ] [ "${../opencode/quota-report.sh}" ] (
        builtins.readFile (../opencode + "/${name}")
      )
    );

  quotaPollers = {
    copilot = mkQuotaPoller "copilot-quota-poll.sh";
    openai = mkQuotaPoller "openai-quota-poll.sh";
    crof = mkQuotaPoller "crof-quota-poll.sh";
    openrouter = mkQuotaPoller "openrouter-quota-poll.sh";
    claude = mkQuotaPoller "claude-quota-poll.sh";
    kimi = mkQuotaPoller "kimi-quota-poll.sh";
  };
in
# senpi-herdr.sh はこの wrapper を env 経由で直接 exec するため、
# writeText (mode 444) ではなく実行ビット付きで生成する必要がある。
writeShellScript "senpi-herdr-child-wrapper.sh" (
  builtins.replaceStrings
    [
      "@quota-script@"
      "@openai-quota-script@"
      "@crof-quota-script@"
      "@openrouter-quota-script@"
      "@claude-quota-script@"
      "@kimi-quota-script@"
    ]
    [
      "${quotaPollers.copilot}"
      "${quotaPollers.openai}"
      "${quotaPollers.crof}"
      "${quotaPollers.openrouter}"
      "${quotaPollers.claude}"
      "${quotaPollers.kimi}"
    ]
    (builtins.readFile ./senpi-herdr-child-wrapper.sh)
)
