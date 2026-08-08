# Base oh-my-openagent (omo) configuration for the "[opencode]" harness section
# of ~/.omo/omo.jsonc. Migrated from the former oc-go profile
# (oh-my-openagent-go.json).
#
# Notes:
# - Uses the post-2026-08-reasoning-unification format (`models` list with
#   `reasoning` entries); the migration marker is pinned in ./default.nix, so
#   reintroducing `fallback_models`/`variant` makes `omo doctor` flag this file.
# - `skills.sources` is injected in ./default.nix (needs configDir).
# - Per-host overrides are deep-merged via packs.opencode.omoOverrides
#   (see module/opencode).
{
  agents = {
    sisyphus = {
      models = [
        "cli-proxy-api/kimi-k3"
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
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/gpt-5.6-terra";
          reasoning = "max";
        }
      ];
    };
    metis = {
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
    prometheus = {
      models = [
        {
          model = "cli-proxy-api/gpt-5.6-sol";
          reasoning = "xhigh";
        }
        {
          model = "cli-proxy-api/glm-5.2";
          reasoning = "max";
        }
      ];
    };
    atlas = {
      models = [
        "cli-proxy-api/kimi-k3"
        { model = "cli-proxy-api/kimi-k2.7-code"; }
      ];
    };
    sisyphus-junior = {
      models = [
        "openrouter/kimi-k3"
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
    multimodal-looker = {
      model = "cli-proxy-api/kimi-k2.7-code";
    };
  };
  categories = {
    visual-engineering = {
      models = [
        "CrofAI/greg-2-super"
        { model = "cli-proxy-api/kimi-k2.7-code"; }
        {
          model = "cli-proxy-api/glm-5.2";
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
    deep = {
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
    artistry = {
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
    quick = {
      models = [
        {
          model = "cli-proxy-api/deepseek-v4-flash";
          reasoning = "max";
        }
        { model = "cli-proxy-api/kimi-k2.7-code"; }
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
    writing = {
      models = [ "cli-proxy-api/kimi-k2.7-code" ];
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
    include_co_authored_by = true;
  };
  runtime_fallback = true;
}
