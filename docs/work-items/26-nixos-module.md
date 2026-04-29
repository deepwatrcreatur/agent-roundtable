# 26 — NixOS Service Module

**Status:** `ready` (cross-repo: targets `unified-nix-configuration`)

## Scope

NixOS module for the roundtable service, to be added to the
`unified-nix-configuration` flake (Q31 decision). Enables:

```bash
nixos-rebuild switch --flake .#homeserver
```

The service will be reachable at `roundtable.deepwatercreature.com` via
the existing Caddy reverse proxy on `router`.

## Proposed module interface

```nix
# In unified-nix-configuration/modules/nixos/roundtable.nix
{ config, lib, pkgs, ... }:
{
  options.services.roundtable = {
    enable = lib.mkEnableOption "roundtable discussion orchestrator";

    port = lib.mkOption {
      type = lib.types.port;
      default = 4000;
    };

    secretKeyBaseFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing SECRET_KEY_BASE";
    };

    githubTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing GitHub PAT";
    };

    phoenixHost = lib.mkOption {
      type = lib.types.str;
      default = "roundtable.deepwatercreature.com";
    };

    oidcIssuerUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Authentik OIDC issuer URL (empty = unauthenticated dev mode)";
    };
  };

  config = lib.mkIf config.services.roundtable.enable {
    systemd.services.roundtable = {
      description = "Roundtable discussion orchestrator";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.roundtable}/bin/roundtable-web";
        EnvironmentFile = [
          config.services.roundtable.secretKeyBaseFile
          config.services.roundtable.githubTokenFile
        ];
        Environment = [
          "PORT=${toString config.services.roundtable.port}"
          "PHX_HOST=${config.services.roundtable.phoenixHost}"
          "OIDC_ISSUER_URL=${config.services.roundtable.oidcIssuerUrl}"
        ];
        DynamicUser = true;
        StateDirectory = "roundtable";
        Restart = "on-failure";
      };
    };
  };
}
```

## Caddy virtual host (in router Caddy config)

```
roundtable.deepwatercreature.com {
  reverse_proxy <homeserver-ip>:4000
}
```

Phoenix LiveView WebSocket note: Caddy's `reverse_proxy` forwards WebSocket
upgrade headers by default. No special config needed beyond the `reverse_proxy`
directive.

## Open decisions (from Q31 conditions)

1. Public (`roundtable.deepwatercreature.com`) vs. VPN-only for external
   collaborator access. If VPN-only: remove the Caddy virtual host and
   configure Tailscale/WireGuard instead.
2. `PHX_HOST` value confirmed: `roundtable.deepwatercreature.com`.
