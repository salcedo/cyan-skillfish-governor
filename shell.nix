{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  inputsFrom = [
    (pkgs.callPackage ./nix/package.nix {})
  ];
  packages = with pkgs; [
    cargo
    rustc
    libdrm
  ];
}
