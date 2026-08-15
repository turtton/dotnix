# Generates ~/.config/opencode/opencode.jsonc (deployed by ./default.nix).
# The cli-proxy-api and CrofAI provider model blocks come from the shared
# ../cli-proxy-models.nix catalog.
{ proxyModels }:
let
  optionalAttrs = c: attrs: if c then attrs else { };

  mkModel =
    m:
    {
      inherit (m) name;
      limit = {
        inherit (m) context output;
      };
    }
    // optionalAttrs (m.reasoning or false) { reasoning = true; }
    // optionalAttrs (m ? variants) {
      variants = builtins.listToAttrs (
        map (v: {
          name = v;
          value = { };
        }) m.variants
      );
    }
    // optionalAttrs (m ? cost) {
      cost = {
        inherit (m.cost) input output;
        cache_read = m.cost.cacheRead;
      };
    };

  pick =
    ids:
    builtins.listToAttrs (
      map (id: {
        name = id;
        value = mkModel proxyModels.${id};
      }) ids
    );
in
{
  "$schema" = "https://opencode.ai/config.json";
  plugin = [
    "oh-my-openagent"
    "opencode-comments-plugin"
    "@simonwjackson/opencode-direnv"
    "opencode-wakatime"
    "opencode-cache-hit"
  ];
  agent.title.model = "opencode-go/minimax-m2.7";
  provider = {
    cli-proxy-api = {
      name = "CLIProxyAPI";
      npm = "@ai-sdk/openai-compatible";
      options.baseURL = "http://127.0.0.1:8317/v1";
      models = pick [
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
    };
    CrofAI = {
      npm = "@ai-sdk/openai-compatible";
      name = "CrofAI";
      options.baseURL = "https://crof.ai/v1";
      models = pick [
        "deepseek-v4-pro"
        "deepseek-v4-pro-0813"
        "deepseek-v4-flash"
        "deepseek-v4-flash-0731"
        "kimi-k3-eco"
        "kimi-k3"
        "kimi-k2.7-code"
        "kimi-k2.6"
        "kimi-k2.5-lightning"
        "glm-5.2"
        "glm-5.1"
        "gemma-4-31b-it"
        "minimax-m2.5"
        "qwen3.5-397b-a17b"
        "greg-2-super"
      ];
    };
  };
}
