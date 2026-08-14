# Builds the senpi models.json document registering the local CLIProxyAPI as
# provider "cli-proxy-api". The provider id must stay "cli-proxy-api" because
# ~/.omo/omo.jsonc [senpi] references models as cli-proxy-api/<id>; the
# catalog is shared with opencode.jsonc via ../cli-proxy-models.nix.
{ proxyModels }:
let
  mkModel =
    id: m:
    {
      inherit id;
      inherit (m) name;
      contextWindow = m.context;
      maxTokens = m.output;
    }
    // (if m.reasoning or false then { reasoning = true; } else { })
    // (if m ? cost then {
      cost = {
        inherit (m.cost) input output;
        cacheRead = m.cost.cacheRead;
        cacheWrite = 0;
      };
    } else { })
    // (if m.reasoning or false then {
      thinkingLevelMap = {
        off = "none";
        minimal = "low";
        low = "low";
        medium = "medium";
        high = "high";
        xhigh = "high";
        max = "high";
      };
      compat.supportsReasoningEffort = true;
    } else { });

  ids = [
    "claude-fable-5"
    "gpt-5.6-sol"
    "gpt-5.6-terra"
    "gpt-5.6-luna"
    "deepseek-v4-pro"
    "deepseek-v4-flash"
    "kimi-k3"
    "kimi-k2.7-code"
    "glm-5.2"
    "glm-5.1"
    "gemma-4-31b-it"
    "minimax-m2.5"
    "qwen3.5-397b-a17b"
    "greg-2-super"
  ];
in
{
  providers."cli-proxy-api" = {
    name = "CLIProxyAPI";
    baseUrl = "http://127.0.0.1:8317/v1";
    api = "openai-completions";
    models = map (id: mkModel id proxyModels.${id}) ids;
  };
}
