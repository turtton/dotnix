# OpenCode harness settings for ~/.omo/omo.jsonc.
{
  agents = {
    sisyphus = {
      models = [
        { model = "cli-proxy-api/kimi-k3"; }
        { model = "cli-proxy-api/kimi-k2.7-code"; }
        {
          model = "cli-proxy-api/gpt-5.6-luna";
          reasoning = "ultra";
        }
      ];
    };
    hephaestus = {
      models = [
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "medium";
        }
        {
          model = "cli-proxy-api/deepseek-v4-pro";
          reasoning = "max";
        }
      ];
    };
    oracle = {
      models = [
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/gpt-5.6-terra";
          reasoning = "max";
        }
      ];
    };
    momus = {
      models = [
        {
          model = "cli-proxy-api/gpt-6-astra";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/glm-5.3";
          reasoning = "max";
        }
      ];
    };
    metis = {
      models = [
        {
          model = "cli-proxy-api/kimi-k3";
          reasoning = "low";
        }
        {
          model = "cli-proxy-api/gpt-5.6-terra";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/glm-5.2";
          reasoning = "max";
        }
      ];
    };
    prometheus = {
      models = [
        {
          model = "cli-proxy-api/kimi-k3";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/gpt-6-astra";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "xhigh";
        }
      ];
    };
    plan = {
      models = [
        {
          model = "cli-proxy-api/kimi-k3";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/glm-5.3";
          reasoning = "max";
        }
      ];
    };
    atlas = {
      models = [
        { model = "cli-proxy-api/kimi-k3"; }
        { model = "cli-proxy-api/kimi-k2.7-code"; }
      ];
    };
    sisyphus-junior = {
      models = [
        { model = "openrouter/kimi-k3"; }
        { model = "cli-proxy-api/kimi-k2.7-code"; }
        {
          model = "cli-proxy-api/glm-5.2";
          reasoning = "max";
        }
      ];
    };
    explore = {
      models = [
        {
          model = "openai/gpt-5.6-luna-fast";
          reasoning = "low";
        }
        {
          model = "cli-proxy-api/deepseek-v4-flash";
          reasoning = "max";
        }
      ];
    };
    librarian = {
      models = [
        {
          model = "openai/gpt-5.6-luna-fast";
          reasoning = "low";
        }
        {
          model = "cli-proxy-api/deepseek-v4-flash";
          reasoning = "max";
        }
      ];
    };
    multimodal-looker = {
      models = [
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "low";
        }
        {
          model = "cli-proxy-api/kimi-k3";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/kimi-k2.7-code";
          reasoning = "max";
        }
      ];
    };
  };
  categories = {
    visual-engineering = {
      models = [
        {
          model = "cli-proxy-api/gpt-6-astra";
          reasoning = "xhigh";
        }
        { model = "cli-proxy-api/kimi-k3"; }
      ];
    };
    ultrabrain = {
      models = [
        {
          model = "cli-proxy-api/gpt-6-astra";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/deepseek-v4-pro";
          reasoning = "max";
        }
      ];
    };
    deep-low = {
      models = [
        {
          model = "cli-proxy-api/gpt-6-astra";
          reasoning = "high";
        }
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "medium";
        }
        {
          model = "cli-proxy-api/glm-5.2";
          reasoning = "max";
        }
      ];
    };
    deep-high = {
      models = [
        {
          model = "cli-proxy-api/gpt-6-astra";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/deepseek-v4-pro";
          reasoning = "max";
        }
      ];
    };
    artistry = {
      models = [
        {
          model = "cli-proxy-api/gpt-6-astra";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/deepseek-v4-pro";
          reasoning = "max";
        }
      ];
    };
    quick = {
      models = [
        {
          model = "openai/gpt-5.6-luna-fast";
          reasoning = "low";
        }
        {
          model = "cli-proxy-api/deepseek-v4-flash";
          reasoning = "off";
        }
      ];
    };
    unspecified-low = {
      models = [
        {
          model = "cli-proxy-api/gpt-5.6-terra";
          reasoning = "high";
        }
        {
          model = "cli-proxy-api/deepseek-v4-pro";
          reasoning = "max";
        }
      ];
    };
    unspecified-high = {
      models = [
        {
          model = "cli-proxy-api/gpt-6-astra";
          reasoning = "high";
        }
        {
          model = "cli-proxy-api/glm-5.3";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/kimi-k3";
          reasoning = "max";
        }
      ];
    };
    writing = {
      models = [
        {
          model = "cli-proxy-api/kimi-k3";
          reasoning = "low";
        }
      ];
    };
  };
  tmux = {
    enabled = true;
  };
  team_mode = {
    enabled = true;
    max_parallel_members = 4;
    tmux_visualization = true;
  };
  background_task = {
    providerConcurrency = {
      openai = 3;
      opencode-go = 10;
      CrofAI = 20;
    };
    circuitBreaker = {
      maxToolCalls = 400;
    };
  };
  git_master = {
    git_env_prefix = "";
    commit_footer = true;
  };
  runtime_fallback = true;
}
