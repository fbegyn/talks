{
  description = "Flake utils demo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      in rec {
        devShell = pkgs.mkShell rec {
          buildInputs = with pkgs; [
            librsvg
            pandoc
            git
            alejandra
            (texlive.combine {
              inherit (texlive)
              collection-latex
              collection-pictures
              collection-latexextra
              collection-langenglish
              collection-basic
              collection-context
              collection-fontsrecommended
              lato
              montserrat
              collection-fontutils
              beamertheme-metropolis
              collection-luatex
              collection-pstricks
              ly1
              ccicons
              collection-latexrecommended;
            }
            )
          ];
        };
      }
    );
}
