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
  }: let
    lib = nixpkgs.lib;

    # Upstream versions releases by git tag only: its release workflow rewrites
    # Cargo.toml's version from the tag at build time but never commits it, so
    # the checked-in Cargo.toml version is a base, not the release version.
    cargoToml = builtins.readFile ./Cargo.toml;
    baseVersion =
      lib.removePrefix "version = \""
      (lib.removeSuffix "\""
        (lib.findFirst (line: lib.hasPrefix "version = " line) "version = \"0.0.0\""
          (lib.splitString "\n" cargoToml)));

    # Flake evaluation is pure and runs from a store copy without .git, so the
    # release tag is not observable. Derive a unique, honest version per
    # revision instead; consumers can override `version` on the package.
    revision = self.shortRev or self.dirtyShortRev or "unknown";
    version = "${baseVersion}-unstable-${self.lastModifiedDate or revision}";
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        packages.default = pkgs.callPackage ./nix/package.nix {inherit version;};

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
            cyan-skillfish-governor-smu = final.callPackage ./nix/package.nix {inherit version;};
          })
        ];

        imports = [./nix/nixos-module.nix];
      };

      nixosModules.cyan-skillfish-governor = self.nixosModules.default;

      overlays.default = final: prev: {
        cyan-skillfish-governor-smu = final.callPackage ./nix/package.nix {inherit version;};
      };
    };
}
