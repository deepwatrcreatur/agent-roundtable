{
  description = "Roundtable - Autonomous multi-agent design orchestrator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

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
            exec elixir -S mix run -e 'Roundtable.CLI.main(System.argv())' -- "$@"
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
        apps.default = flake-utils.lib.mkApp { drv = roundtableScript; };
      }
    );
}
