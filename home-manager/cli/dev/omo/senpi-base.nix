# Native harness settings for ~/.omo/omo.jsonc.
{
  agents = {
    explore = {
      models = [
        {
          model = "cli-proxy-api/glm-5.2";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/gpt-5.6-luna";
          reasoning = "medium";
        }
      ];
    };
    librarian = {
      models = [
        {
          model = "cli-proxy-api/glm-5.2";
          reasoning = "max";
        }
        {
          model = "cli-proxy-api/gpt-5.6-luna";
          reasoning = "medium";
        }
      ];
    };
    plan-consultant = {
      models = [
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "xhigh";
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
    plan-reviewer = {
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
  };
  categories = {
    quick = {
      models = [
        {
          model = "cli-proxy-api/deepseek-v4-flash";
          reasoning = "max";
        }
        "cli-proxy-api/kimi-k2.7-code"
      ];
    };
    unspecified-low = {
      models = [
        {
          model = "cli-proxy-api/glm-5.2";
          reasoning = "max";
        }
      ];
    };
    unspecified-high = {
      models = [ "cli-proxy-api/kimi-k3" ];
    };
    deep-low = {
      models = [
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "high";
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
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/deepseek-v4-pro";
          reasoning = "max";
        }
      ];
    };
    ultrabrain = {
      models = [
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
    architect = {
      models = [
        {
          model = "cli-proxy-api/claude-fable-5";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "high";
        }
        {
          model = "cli-proxy-api/kimi-k3";
          reasoning = "xhigh";
        }
        "cli-proxy-api/glm-5.2"
      ];
    };
    artistry = {
      models = [
        {
          model = "cli-proxy-api/claude-fable-5";
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
    visual-engineering = {
      models = [
        "cli-proxy-api/greg-2-super"
        "cli-proxy-api/kimi-k2.7-code"
        {
          model = "cli-proxy-api/glm-5.2";
          reasoning = "max";
        }
      ];
    };
    writing = {
      models = [ "cli-proxy-api/kimi-k2.7-code" ];
    };
  };
}
