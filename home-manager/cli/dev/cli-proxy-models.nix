# Single source of truth for models served by the local CLIProxyAPI
# (127.0.0.1:8317). Consumed by:
#   - ./opencode/opencode-json.nix  -> ~/.config/opencode/opencode.jsonc
#   - ./senpi/default.nix           -> ~/.senpi/agent/models.json
# Optional per-model keys: reasoning, image (vision input), variants (opencode), cost.
{
  "claude-fable-5" = {
    name = "Claude Fable 5";
    reasoning = true;
    image = true;
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
    image = true;
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
    image = true;
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
    image = true;
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
  "deepseek-v4-pro-0813" = {
    name = "DeepSeek V4 Pro 0813";
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
      cacheRead = 0.01;
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
  "deepseek-v4-flash-0731" = {
    name = "DeepSeek V4 Flash 0731";
    reasoning = true;
    variants = [
      "max"
      "high"
      "medium"
    ];
    context = 1000000;
    output = 131072;
    cost = {
      input = 0.08;
      output = 0.10;
      cacheRead = 0.003;
    };
  };
  "kimi-k3" = {
    name = "Kimi K3";
    reasoning = true;
    image = true;
    variants = [
      "max"
      "high"
      "medium"
    ];
    context = 1048576;
    output = 131072;
    cost = {
      input = 2;
      output = 8;
      cacheRead = 0.25;
    };
  };
  "kimi-k3-eco" = {
    name = "Kimi K3 Eco";
    reasoning = true;
    image = true;
    variants = [
      "max"
      "high"
      "medium"
    ];
    context = 1048576;
    output = 131072;
    cost = {
      input = 1;
      output = 4;
      cacheRead = 0.1;
    };
  };
  "kimi-k2.7-code" = {
    name = "Kimi K2.7 Code";
    reasoning = true;
    image = true;
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
    image = true;
    context = 262144;
    output = 262144;
    cost = {
      input = 0.5;
      output = 1.99;
      cacheRead = 0.05;
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
      input = 0.3;
      output = 1.05;
      cacheRead = 0.05;
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
    image = true;
    context = 262144;
    output = 262144;
    cost = {
      input = 0.1;
      output = 0.3;
      cacheRead = 0.02;
    };
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
    cost = {
      input = 0.35;
      output = 1.75;
      cacheRead = 0.07;
    };
  };
  "greg-2-super" = {
    name = "Greg2 Super";
    reasoning = true;
    context = 229376;
    output = 229376;
    cost = {
      input = 1.5;
      output = 5;
      cacheRead = 0.25;
    };
  };
}
