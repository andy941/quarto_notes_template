{
  description = ''
    Basic Nix Flake for a Development Shell

    # Run inheriting your environment for development
    nix develop -c $SHELL

    # Run without your environment for production
    # (to check that all the necessary packages are specified in the flake)
    nix develop --ignore-environment

    # Build a docker image
    nix build .#<system>.prod

  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        # Import nixpkgs for the current system
        pkgs = import nixpkgs { inherit system; };
        pyPkgs = (ps: with ps; [ pandas numpy matplotlib ]);
        rPkgs = (with pkgs.rPackages; [
          languageserver
          styler
          ggplot2
          tidyverse
          reticulate
          ggpubr
          ggthemes
          kableExtra
          plotly
        ]);

        prodPackages = with pkgs; [
          # Add dependencies
          zsh
          pyright
          black
          (pkgs.rWrapper.override { packages = rPkgs; })
          (pkgs.python3.withPackages (pyPkgs))
          (quarto.override {
            extraPythonPackages = pyPkgs;
            extraRPackages = rPkgs;
          })
        ];
      in {
        devShells.default = pkgs.mkShell {

          packages = prodPackages;

          shellHook = ''
            export RETICULATE_PYTHON=$(which python)

            echo "R:                       ${pkgs.rWrapper}"
            echo "Python:                  ${pkgs.python3}"
            echo "Reticulate's Python:     ${pkgs.python3}"
            echo ""
            echo "Welcome to Quarto model website for data science!"
          '';

          # Allow unfree packages (by default they are not enabled)
          allowUnfree = false;
        };
      });
}
