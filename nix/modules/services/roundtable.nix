{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.roundtable;
  stateHome = "/var/lib/${cfg.stateDir}";

  credential =
    name: file:
    lib.optional (file != null) "${name}:${toString file}";

  exportOptionalCredential = envName: credentialName: ''
    if [ -n "$credential_dir" ] && [ -f "$credential_dir/${credentialName}" ]; then
      export ${envName}="$(cat "$credential_dir/${credentialName}")"
    fi
  '';
in
{
  options.services.roundtable = {
    enable = lib.mkEnableOption "Vaglio / roundtable web service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs."roundtable-web";
      description = "Package providing the roundtable web entrypoint.";
    };

    cliPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.roundtable;
      description = "CLI package installed for local maintainer/TUI workflows.";
    };

    prewarmPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs."roundtable-prewarm-public-repo-cache";
      description = "Package providing the public-repo cache prewarm command.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4000;
      description = "HTTP listen port for the Vaglio web UI.";
    };

    phoenixHost = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = "Public hostname used by Phoenix URL generation.";
    };

    oidcIssuerUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional OIDC issuer URL. Leave empty for unauthenticated mode.";
    };

    roundtableRepo = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional GitHub repo slug shown/managed by the web dashboard.";
    };

    roundtableBrief = lib.mkOption {
      type = lib.types.str;
      default = "docs/design/BRIEF.md";
      description = "Default BRIEF path used by the dashboard trigger action.";
    };

    localPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional local discussion repo path used for conflict inspection.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "roundtable";
      description = "StateDirectory name under /var/lib.";
    };

    enableTuiTooling = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install CLI/TUI-adjacent maintainer tools alongside the service.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages to install on the host for local workflows.";
    };

    prewarmPublicRepoCache = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Warm cached public demo snapshots after the roundtable service starts.";
      };

      demos = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "forgejo" "kubernetes" "nixpkgs" ];
        description = "Demo ids to prewarm into the persistent public-repo cache.";
      };

      timeoutMs = lib.mkOption {
        type = lib.types.int;
        default = 30000;
        description = "Per-demo timeout used by the public repo prewarm command.";
      };
    };

    secretKeyBaseFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional file containing SECRET_KEY_BASE. If unset, one is generated in the state directory.";
    };

    githubTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional file containing GH_TOKEN for GitHub-backed rounds.";
    };

    anthropicApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional Anthropic API key file.";
    };

    openaiApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional OpenAI API key file.";
    };

    geminiApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional Gemini API key file.";
    };

    deepseekApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional DeepSeek API key file.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    environment.systemPackages =
      lib.optionals cfg.enableTuiTooling (
        [
          cfg.cliPackage
          cfg.package
          cfg.prewarmPackage
          pkgs.git
          pkgs.gh
          pkgs.dolt
          pkgs.jujutsu
          pkgs.tmux
        ]
        ++ cfg.extraPackages
      );

    systemd.services.roundtable = {
      description = "Vaglio / roundtable discussion orchestrator";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = with pkgs; [
        coreutils
        openssl
        git
        gh
        dolt
        jujutsu
      ];

      serviceConfig = {
        Type = "simple";
        WorkingDirectory = stateHome;
        StateDirectory = cfg.stateDir;
        LoadCredential =
          credential "secret_key_base" cfg.secretKeyBaseFile
          ++ credential "github_token" cfg.githubTokenFile
          ++ credential "anthropic_api_key" cfg.anthropicApiKeyFile
          ++ credential "openai_api_key" cfg.openaiApiKeyFile
          ++ credential "gemini_api_key" cfg.geminiApiKeyFile
          ++ credential "deepseek_api_key" cfg.deepseekApiKeyFile;
        Environment =
          [
            "HOME=${stateHome}"
            "XDG_STATE_HOME=${stateHome}"
            "MIX_ENV=prod"
            "ROUNDTABLE_WEB=true"
            "ROUNDTABLE_STATE_DIR=${stateHome}/state"
            "PORT=${toString cfg.port}"
            "PHX_HOST=${cfg.phoenixHost}"
            "HOST=${cfg.phoenixHost}"
            "OIDC_ISSUER_URL=${cfg.oidcIssuerUrl}"
            "ROUNDTABLE_REPO=${cfg.roundtableRepo}"
            "ROUNDTABLE_BRIEF=${cfg.roundtableBrief}"
          ]
          ++ lib.optional (cfg.localPath != "") "ROUNDTABLE_LOCAL_PATH=${cfg.localPath}";
        ExecStart = pkgs.writeShellScript "roundtable-start" ''
          set -eu

          mkdir -p "$HOME/state"
          credential_dir="''${CREDENTIALS_DIRECTORY:-}"

          if [ -n "$credential_dir" ] && [ -f "$credential_dir/secret_key_base" ]; then
            export SECRET_KEY_BASE="$(cat "$credential_dir/secret_key_base")"
          elif [ -f "$HOME/secret_key_base" ]; then
            export SECRET_KEY_BASE="$(cat "$HOME/secret_key_base")"
          else
            openssl rand -hex 32 > "$HOME/secret_key_base"
            chmod 600 "$HOME/secret_key_base"
            export SECRET_KEY_BASE="$(cat "$HOME/secret_key_base")"
          fi

          ${exportOptionalCredential "GH_TOKEN" "github_token"}
          ${exportOptionalCredential "ANTHROPIC_API_KEY" "anthropic_api_key"}
          ${exportOptionalCredential "OPENAI_API_KEY" "openai_api_key"}
          ${exportOptionalCredential "GEMINI_API_KEY" "gemini_api_key"}
          ${exportOptionalCredential "DEEPSEEK_API_KEY" "deepseek_api_key"}

          exec ${cfg.package}/bin/roundtable-web
        '';
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    systemd.services.roundtable-prewarm-public-repo-cache = lib.mkIf cfg.prewarmPublicRepoCache.enable {
      description = "Warm cached public-repo snapshots for the roundtable demo";
      wantedBy = [ "multi-user.target" ];
      after = [ "roundtable.service" ];
      wants = [ "roundtable.service" ];
      path = with pkgs; [
        coreutils
      ];

      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = stateHome;
        StateDirectory = cfg.stateDir;
        LoadCredential =
          credential "secret_key_base" cfg.secretKeyBaseFile
          ++ credential "github_token" cfg.githubTokenFile
          ++ credential "anthropic_api_key" cfg.anthropicApiKeyFile
          ++ credential "openai_api_key" cfg.openaiApiKeyFile
          ++ credential "gemini_api_key" cfg.geminiApiKeyFile
          ++ credential "deepseek_api_key" cfg.deepseekApiKeyFile;
        Environment = [
          "HOME=${stateHome}"
          "XDG_STATE_HOME=${stateHome}"
          "MIX_ENV=prod"
          "ROUNDTABLE_STATE_DIR=${stateHome}/state"
          "ROUNDTABLE_PUBLIC_REPO_CACHE_DIR=${stateHome}/state/public-repo-cache"
        ];
        ExecStart = pkgs.writeShellScript "roundtable-prewarm-public-repo-cache-start" ''
          set -eu
          mkdir -p "$HOME/state" "$HOME/state/public-repo-cache"
          credential_dir="''${CREDENTIALS_DIRECTORY:-}"

          if [ -n "$credential_dir" ] && [ -f "$credential_dir/secret_key_base" ]; then
            export SECRET_KEY_BASE="$(cat "$credential_dir/secret_key_base")"
          elif [ -f "$HOME/secret_key_base" ]; then
            export SECRET_KEY_BASE="$(cat "$HOME/secret_key_base")"
          else
            echo "SECRET_KEY_BASE unavailable for prewarm" >&2
            exit 1
          fi

          ${exportOptionalCredential "GH_TOKEN" "github_token"}
          ${exportOptionalCredential "ANTHROPIC_API_KEY" "anthropic_api_key"}
          ${exportOptionalCredential "OPENAI_API_KEY" "openai_api_key"}
          ${exportOptionalCredential "GEMINI_API_KEY" "gemini_api_key"}
          ${exportOptionalCredential "DEEPSEEK_API_KEY" "deepseek_api_key"}

          exec ${cfg.prewarmPackage}/bin/roundtable-prewarm-public-repo-cache \
            --timeout-ms ${toString cfg.prewarmPublicRepoCache.timeoutMs} \
            ${lib.escapeShellArgs cfg.prewarmPublicRepoCache.demos}
        '';
      };
    };
  };
}
