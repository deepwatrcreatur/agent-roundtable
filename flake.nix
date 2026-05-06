{
  description = "Vaglio / agent-roundtable standalone deployment and development flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev:
        let
          roundtableSrc = builtins.path {
            path = ./roundtable;
            name = "roundtable-src";
          };

          mkMixWrapper = { name, script }:
            final.writeShellApplication {
              inherit name;
              runtimeInputs = with final; [
                bash
                coreutils
                curl
                elixir
                beam.packages.erlang.erlang
                git
                gh
                dolt
                jujutsu
                openssl
              ];
              text = ''
                set -eu

                state_home="''${XDG_STATE_HOME:-}"
                if [ -z "$state_home" ]; then
                  if [ -n "''${HOME:-}" ]; then
                    state_home="$HOME/.local/state/roundtable"
                  else
                    state_home="$PWD/.roundtable-state"
                  fi
                fi
                mix_home="$state_home/mix"
                deps_path="$state_home/deps"
                build_root="$state_home/build"

                mkdir -p "$state_home" "$mix_home" "$deps_path" "$build_root"

                export MIX_ENV="''${MIX_ENV:-prod}"
                export MIX_HOME="$mix_home"
                export HEX_HOME="$mix_home/hex"
                export MIX_ARCHIVES="$mix_home/archives"
                export MIX_DEPS_PATH="$deps_path"
                export MIX_BUILD_ROOT="$build_root"

                cd ${roundtableSrc}

                mix local.hex --force >/dev/null 2>&1 || true
                mix local.rebar --force >/dev/null 2>&1 || true
                mix deps.get >/dev/null

                ${script}
              '';
            };
        in
        {
          roundtable = mkMixWrapper {
            name = "roundtable";
            script = ''exec mix run -e 'Roundtable.CLI.main(System.argv())' -- "$@"'';
          };

          "roundtable-web" = mkMixWrapper {
            name = "roundtable-web";
            script = ''exec mix run --no-halt'';
          };
        };

      nixosModuleSet = {
        roundtable = import ./nix/modules/services/roundtable.nix;
        vaglio-lxc = import ./nix/modules/profiles/vaglio-lxc.nix;
      };
    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          packages = {
            default = pkgs.roundtable;
            roundtable = pkgs.roundtable;
            "roundtable-web" = pkgs."roundtable-web";
          };

          apps = {
            default = {
              type = "app";
              program = "${pkgs.roundtable}/bin/roundtable";
            };

            "roundtable-web" = {
              type = "app";
              program = "${pkgs."roundtable-web"}/bin/roundtable-web";
            };
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              elixir
              beam.packages.erlang.erlang
              git
              gh
              dolt
              jujutsu
              tmux
            ];
          };
        }
      ) // {
        overlays.default = overlay;
        nixosModules = nixosModuleSet;

        nixosConfigurations.vaglio = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ ... }: { nixpkgs.overlays = [ self.overlays.default ]; })
            nixosModuleSet.roundtable
            nixosModuleSet.vaglio-lxc
          ];
        };
      };
}
