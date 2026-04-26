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
        erlang = pkgs.erlang;
        elixir = pkgs.beam.packages.erlang.elixir;
        rebar3 = pkgs.rebar3;
        gh = pkgs.gh;

        # Q1-researched CLI versions on the developer machine were:
        # claude-code 2.1.83, codex 0.116.0, gemini-cli 0.35.0.
        # The nixpkgs revision pinned by this flake currently exposes:
        # claude-code 2.1.25, codex 0.92.0, gemini-cli 0.25.2.
        # Keep them explicitly listed here so later work can upgrade the flake
        # in one place when matching package revisions are available.
        claudeCode = pkgs.claude-code;
        codex = pkgs.codex;
        gemini = pkgs.gemini-cli;

        runtimeInputs = [
          elixir
          erlang
          rebar3
          gh
          claudeCode
          codex
          gemini
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = runtimeInputs;

          shellHook = ''
            echo "roundtable devShell"
            echo "  elixir: $(elixir --version | head -n 1)"
            echo "  gh: $(gh --version | head -n 1)"
            echo "  claude: $(claude --version | head -n 1)"
            echo "  codex: $(codex --version | tail -n 1)"
            echo "  gemini: $(readlink -f "$(command -v gemini)")"
          '';
        };

        packages.default = pkgs.writeShellApplication {
          name = "roundtable";
          runtimeInputs = runtimeInputs;
          text = ''
            cd ${./.}
            exec mix run -e 'Roundtable.CLI.main(System.argv())' -- "$@"
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/roundtable";
        };
      }
    );
}
