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
        elixir = pkgs.beam.packages.erlang.elixir;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            elixir
            pkgs.beam.packages.erlang.erlang
            pkgs.gh
            pkgs.jujutsu
            pkgs.dolt
            # Mock or real agent CLIs if available
          ];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "roundtable";
          version = "0.1.0";
          src = ./.;
          buildInputs = [ elixir ];
          installPhase = ''
            mkdir -p $out/bin
            # Wrap mix run as a standalone binary
            cat > $out/bin/roundtable <<EOF
            #!/bin/sh
            exec elixir -S mix run -e 'Roundtable.CLI.main(System.argv())' -- "\$@"
            EOF
            chmod +x $out/bin/roundtable
          '';
        };
      }
    );
}
