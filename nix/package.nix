{
  lib,
  rustPlatform,
  pkg-config,
  libdrm,
  # Overridable; the flake passes a revision-derived value. Upstream versions
  # releases by git tag only, so there is no reliable checked-in version.
  version ? "0.0.0-unstable",
}:
  rustPlatform.buildRustPackage {
    pname = "cyan-skillfish-governor-smu";
    inherit version;

    src = ../.;

    cargoLock.lockFile = ../Cargo.lock;

    nativeBuildInputs = [pkg-config];

    buildInputs = [libdrm];

    env.CYAN_SKILLFISH_GOVERNOR_VERSION = version;

    doCheck = true;

    postInstall = ''
      install -Dm644 $src/com.cyanskillfish.Governor.conf \
        $out/share/dbus-1/system.d/com.cyanskillfish.Governor.conf

      install -Dm644 $src/default-config.toml \
        $out/share/cyan-skillfish-governor-smu/config.toml

      install -Dm644 $src/cyan-skillfish-governor-smu.service \
        $out/lib/systemd/system/cyan-skillfish-governor-smu.service

      install -Dm755 $src/scripts/cyan-skillfish-performance-mode \
        $out/bin/cyan-skillfish-performance-mode
    '';

    meta = with lib; {
      description = "Adaptive GPU frequency governor for AMD Cyan Skillfish APU";
      homepage = "https://github.com/filippor/cyan-skillfish-governor";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "cyan-skillfish-governor-smu";
      maintainers = [];
    };
  }
