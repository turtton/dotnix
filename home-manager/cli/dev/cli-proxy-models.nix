# Single source of truth for models served by the local CLIProxyAPI
# (127.0.0.1:8317). Consumed by:
#   - ./opencode/opencode-json.nix  -> ~/.config/opencode/opencode.jsonc
#   - ./senpi/default.nix           -> ~/.senpi/agent/models.json
# Optional per-model keys: reasoning, variants (opencode), cost.
{
  "claude-fable-5" = {
    name = "Claude Fable 5";
    reasoning = true;
    variants = [
      "max"
      "xhigh"
      "high"
      "medium"
      "low"
    ];
    context = 1000000;
    output = 128000;
    cost = {
      input = 10;
      output = 50;
      cacheRead = 1;
    };
  };
  "gpt-5.6-sol" = {
    name = "GPT-5.6 Sol";
    reasoning = true;
    variants = [
      "max"
      "xhigh"
      "high"
      "medium"
      "low"
    ];
    context = 1050000;
    output = 128000;
  };
  "gpt-5.6-terra" = {
    name = "GPT-5.6 Terra";
    reasoning = true;
    variants = [
      "max"
      "xhigh"
      "high"
      "medium"
      "low"
    ];
    context = 1050000;
    output = 128000;
    cost = {
      input = 2.5;
      output = 15;
      cacheRead = 0.25;
    };
  };
  "gpt-5.6-luna" = {
    name = "GPT-5.6 Luna";
    reasoning = true;
    variants = [
      "max"
      "xhigh"
      "high"
      "medium"
      "low"
    ];
    context = 1050000;
    output = 128000;
    cost = {
      input = 1;
      output = 6;
      cacheRead = 0.1;
    };
  };
  "deepseek-v4-pro" = {
    name = "DeepSeek V4 Pro";
    reasoning = true;
    variants = [
      "max"
      "high"
      "medium"
    ];
    context = 1000000;
    output = 131072;
    cost = {
      input = 0.35;
      output = 0.8;
      cacheRead = 0.003;
    };
  };
  "deepseek-v4-flash" = {
    name = "DeepSeek V4 Flash";
    reasoning = true;
    variants = [
      "max"
      "high"
      "medium"
    ];
    context = 1000000;
    output = 131072;
    cost = {
      input = 0.12;
      output = 0.21;
      cacheRead = 0.003;
    };
  };
  "kimi-k3" = {
    name = "Kimi K3";
    reasoning = true;
    variants = [
      "max"
      "high"
      "medium"
    ];
    context = 1048576;
    output = 131072;
    cost = {
      input = 3;
      output = 15;
      cacheRead = 0.3;
    };
  };
  "kimi-k2.7-code" = {
    name = "Kimi K2.7 Code";
    reasoning = true;
    variants = [
      "max"
      "high"
      "medium"
    ];
    context = 262144;
    output = 262144;
    cost = {
      input = 0.55;
      output = 2.25;
      cacheRead = 0.05;
    };
  };
  "kimi-k2.6" = {
    name = "Kimi K2.6";
    reasoning = true;
    context = 262144;
    output = 262144;
  };
  "kimi-k2.5-lightning" = {
    name = "Kimi K2.5 Lightning";
    reasoning = true;
    context = 131072;
    output = 32768;
    cost = {
      input = 1.0;
      output = 3.0;
      cacheRead = 0.2;
    };
  };
  "glm-5.2" = {
    name = "GLM-5.2";
    reasoning = true;
    variants = [
      "max"
      "high"
      "medium"
    ];
    context = 1000000;
    output = 131072;
    cost = {
      input = 0.5;
      output = 2.2;
      cacheRead = 0.08;
    };
  };
  "glm-5.1" = {
    name = "GLM-5.1";
    reasoning = true;
    context = 1000000;
    output = 131072;
    cost = {
      input = 0.45;
      output = 2.15;
      cacheRead = 0.08;
    };
  };
  "gemma-4-31b-it" = {
    name = "Gemma 4 31B IT";
    context = 262144;
    output = 262144;
  };
  "minimax-m2.5" = {
    name = "Minimax M2.5";
    reasoning = true;
    context = 204144;
    output = 131072;
  };
  "qwen3.5-397b-a17b" = {
    name = "Qwen3.5 397B A17B";
    reasoning = true;
    context = 262144;
    output = 262144;
  };
  "greg-2-super" = {
    name = "Greg2 Super";
    reasoning = true;
    context = 229376;
    output = 229376;
  };
}
