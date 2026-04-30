{
  description = "Roundtable - Autonomous multi-agent design orchestrator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "claude-code"
            ];
        };

        beamPkgs = pkgs.beam.packages.erlang;

        roundtableScript = pkgs.writeShellApplication {
          name = "roundtable";
          runtimeInputs = [
            beamPkgs.elixir
            beamPkgs.erlang
            pkgs.git
            pkgs.gh
            pkgs.claude-code
            pkgs.codex
            pkgs.gemini-cli
          ];

          text = ''
            mix compile
            exec elixir -S mix run --no-compile -e 'Roundtable.CLI.main(System.argv())' -- "$@"
          '';
        };

        roundtableWebScript = pkgs.writeShellApplication {
          name = "roundtable-web";
          runtimeInputs = [
            beamPkgs.elixir
            beamPkgs.erlang
            pkgs.git
            pkgs.gh
            pkgs.claude-code
            pkgs.codex
            pkgs.gemini-cli
          ];

          text = ''
            mix compile
            exec elixir -S mix run --no-halt
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            beamPkgs.elixir
            beamPkgs.erlang
            pkgs.git
            pkgs.gh
            pkgs.claude-code
            pkgs.codex
            pkgs.gemini-cli
          ];

          shellHook = ''
            echo "Roundtable dev shell"
            echo "Expected env vars: ANTHROPIC_API_KEY OPENAI_API_KEY GEMINI_API_KEY GH_TOKEN"
            echo "CLI package set from locked nixpkgs: claude-code, codex, gemini-cli"
          '';
        };

        packages.default = roundtableScript;
        packages.roundtable-web = roundtableWebScript;
        apps.default = flake-utils.lib.mkApp { drv = roundtableScript; };
        apps.roundtable-web = flake-utils.lib.mkApp { drv = roundtableWebScript; };
      }
    );
}
