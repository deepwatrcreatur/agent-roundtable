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
                runtime_namespace="''${ROUNDTABLE_RUNTIME_NAMESPACE:-${name}}"
                runtime_root="$state_home/runtime/$runtime_namespace"
                mix_home="$runtime_root/mix"
                deps_path="$runtime_root/deps"
                build_root="$runtime_root/build"
                runtime_src="$runtime_root/src"
                source_rev='${roundtableSrc}'
                source_marker="$runtime_src/.roundtable-source-rev"
                deps_marker="$runtime_root/.roundtable-deps-rev"
                setup_lock="$runtime_root/.setup-lock"
                runtime_tmp=""
                refresh_runtime=0

                cleanup() {
                  if [ -n "$runtime_tmp" ] && [ -d "$runtime_tmp" ]; then
                    rm -rf "$runtime_tmp"
                  fi
                  rmdir "$setup_lock" 2>/dev/null || true
                }

                trap cleanup EXIT

                mkdir -p "$state_home" "$runtime_root" "$mix_home" "$deps_path" "$build_root"

                while ! mkdir "$setup_lock" 2>/dev/null; do
                  sleep 1
                done

                if [ ! -d "$runtime_src" ] || [ ! -f "$source_marker" ] || [ "$(cat "$source_marker")" != "$source_rev" ]; then
                  runtime_tmp="$(mktemp -d "$runtime_root/src.tmp.XXXXXX")"
                  cp -R ${roundtableSrc}/. "$runtime_tmp"/
                  chmod -R u+w "$runtime_tmp"
                  printf '%s\n' "$source_rev" > "$runtime_tmp/.roundtable-source-rev"
                  rm -rf "$deps_path" "$build_root"
                  mkdir -p "$deps_path" "$build_root"
                  rm -rf "$runtime_src"
                  mv "$runtime_tmp" "$runtime_src"
                  runtime_tmp=""
                  refresh_runtime=1
                fi

                export MIX_ENV="''${MIX_ENV:-prod}"
                export MIX_HOME="$mix_home"
                export HEX_HOME="$mix_home/hex"
                export MIX_ARCHIVES="$mix_home/archives"
                export MIX_DEPS_PATH="$deps_path"
                export MIX_BUILD_ROOT="$build_root"

                cd "$runtime_src"

                mix local.hex --force >/dev/null 2>&1 || true
                mix local.rebar --force >/dev/null 2>&1 || true
                if [ "$refresh_runtime" -eq 1 ] || [ ! -f "$deps_marker" ] || [ "$(cat "$deps_marker")" != "$source_rev" ]; then
                  mix deps.get >/dev/null
                  printf '%s\n' "$source_rev" > "$deps_marker"
                fi

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

          "roundtable-prewarm-public-repo-cache" = mkMixWrapper {
            name = "roundtable-prewarm-public-repo-cache";
            script = ''
              export ROUNDTABLE_WEB="''${ROUNDTABLE_WEB:-false}"
              exec mix run --no-start -e 'Mix.Tasks.Roundtable.PrewarmPublicRepoCache.run(System.argv())' -- "$@"
            '';
          };
        };

      nixosModuleSet = {
        roundtable = import ./nix/modules/services/roundtable.nix;
        vaglio-base = import ./nix/modules/profiles/vaglio-base.nix;
        vaglio-lxc = import ./nix/modules/profiles/vaglio-lxc.nix;
        vaglio-installer-iso = import ./nix/modules/profiles/vaglio-installer-iso.nix;
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
            "roundtable-prewarm-public-repo-cache" = pkgs."roundtable-prewarm-public-repo-cache";
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

            "roundtable-prewarm-public-repo-cache" = {
              type = "app";
              program = "${pkgs."roundtable-prewarm-public-repo-cache"}/bin/roundtable-prewarm-public-repo-cache";
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

        nixosConfigurations.vaglio-installer = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixosModuleSet.vaglio-installer-iso
          ];
        };
      };
}
