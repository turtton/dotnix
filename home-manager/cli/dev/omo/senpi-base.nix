# Base oh-my-openagent (omo) configuration for the "[senpi]" harness section
# of ~/.omo/omo.jsonc. Ported from the live config that senpi had written
# itself (preserved in ~/.omo/omo.jsonc.old) before the opencode activation
# started overwriting the unified file.
#
# Notes:
# - Uses the post-2026-08-reasoning-unification format (`models` list with
#   `reasoning` entries); the migration marker is pinned in ./default.nix.
# - Model providers here (openai-codex, crofai, kimi-coding, anthropic) are
#   senpi-side names and intentionally differ from the "[opencode]" section.

{
  agents = {
    explore = {
      models = [
        "crofai/deepseek-v4-flash-0731"
        "crofai/glm-5.2"
        "kimi-coding/kimi-k3"
        "crofai/kimi-k3-eco"
      ];
    };
    librarian = {
      models = [
        "crofai/deepseek-v4-flash-0731"
        "crofai/glm-5.2"
        "kimi-coding/kimi-k3"
        "crofai/kimi-k3-eco"
      ];
    };
    metis = {
      models = [
        {
          model = "anthropic/claude-opus-5";
          reasoning = "high";
        }
        {
          model = "openai-codex/gpt-5.6-sol";
          reasoning = "high";
        }
        {
          model = "kimi-coding/kimi-k3";
          reasoning = "low";
        }
        "crofai/kimi-k3-eco"
      ];
    };
    momus = {
      models = [
        {
          model = "openai-codex/gpt-5.6-sol";
          reasoning = "xhigh";
        }
        {
          model = "openai-codex/gpt-5.6-terra";
          reasoning = "max";
        }
        {
          model = "anthropic/claude-opus-5";
          reasoning = "max";
        }
        "crofai/glm-5.2"
        {
          model = "kimi-coding/kimi-k3";
          reasoning = "xhigh";
        }
        "crofai/kimi-k3-eco"
      ];
    };
  };
  categories = {
    quick = {
      models = [
        "crofai/deepseek-v4-flash-0731"
        "crofai/glm-5.2"
        "kimi-coding/kimi-k3"
        "crofai/kimi-k3-eco"
      ];
    };
    unspecified-low = {
      models = [
        {
          model = "openai-codex/gpt-5.6-luna";
          reasoning = "xhigh";
        }
        "kimi-coding/kimi-k3"
        "crofai/kimi-k3-eco"
      ];
    };
    unspecified-high = {
      models = [
        {
          model = "kimi-coding/kimi-k3";
          reasoning = "max";
        }
        {
          model = "openai-codex/gpt-5.6-sol";
          reasoning = "high";
        }
        {
          model = "anthropic/claude-opus-5";
          reasoning = "high";
        }
        "crofai/glm-5.2"
        "crofai/kimi-k3-eco"
      ];
    };
    deep = {
      models = [
        {
          model = "openai-codex/gpt-5.6-sol";
          reasoning = "medium";
        }
        {
          model = "anthropic/claude-opus-5";
          reasoning = "high";
        }
        "crofai/glm-5.2"
        {
          model = "kimi-coding/kimi-k3";
          reasoning = "xhigh";
        }
        "crofai/kimi-k3-eco"
      ];
    };
    ultrabrain = {
      models = [
        {
          model = "openai-codex/gpt-5.6-sol";
          reasoning = "xhigh";
        }
        {
          model = "anthropic/claude-opus-5";
          reasoning = "high";
        }
        "crofai/glm-5.2"
        {
          model = "kimi-coding/kimi-k3";
          reasoning = "xhigh";
        }
        "crofai/kimi-k3-eco"
      ];
    };
    architect = {
      models = [
        {
          model = "anthropic/claude-fable-5";
          reasoning = "xhigh";
        }
        {
          model = "openai-codex/gpt-5.6-sol";
          reasoning = "high";
        }
        {
          model = "kimi-coding/kimi-k3";
          reasoning = "xhigh";
        }
        "crofai/glm-5.2"
        "crofai/kimi-k3-eco"
      ];
    };
    artistry = {
      models = [
        {
          model = "anthropic/claude-fable-5";
          reasoning = "xhigh";
        }
        "openai-codex/gpt-5.6-sol"
        "crofai/glm-5.2"
        {
          model = "kimi-coding/kimi-k3";
          reasoning = "xhigh";
        }
        "crofai/kimi-k3-eco"
      ];
    };
    visual-engineering = {
      models = [
        "crofai/greg-2-super"
        {
          model = "kimi-coding/kimi-k3";
          reasoning = "xhigh";
        }
        "crofai/glm-5.2"
        "crofai/kimi-k3-eco"
      ];
    };
    writing = {
      models = [
        {
          model = "kimi-coding/kimi-k3";
          reasoning = "low";
        }
        "openai-codex/gpt-5.6-luna"
        "crofai/kimi-k3-eco"
      ];
    };
  };
}
