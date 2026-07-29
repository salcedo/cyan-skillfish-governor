{
  description = "Adaptive GPU frequency governor for AMD Cyan Skillfish APU";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        packages.default = pkgs.callPackage ./nix/package.nix {};

        devShells.default = pkgs.mkShell {
          inputsFrom = [self.packages.${system}.default];
          packages = with pkgs; [
            cargo
            rustc
            libdrm
          ];
        };
      }
    )
    // {
      nixosModules.default = {lib, ...}: {
        nixpkgs.overlays = [
          (final: prev: {
            cyan-skillfish-governor-smu = final.callPackage ./nix/package.nix {};
          })
        ];

        imports = [./nix/nixos-module.nix];
      };

      nixosModules.cyan-skillfish-governor = self.nixosModules.default;

      overlays.default = final: prev: {
        cyan-skillfish-governor-smu = final.callPackage ./nix/package.nix {};
      };
    };
}
