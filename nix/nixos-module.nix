{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.cyan-skillfish-governor;
  settingsFormat = pkgs.formats.toml {};
in {
  options.hardware.cyan-skillfish-governor = {
    enable = lib.mkEnableOption ''
      the Cyan Skillfish GPU governor daemon

      This enables an adaptive GPU frequency/voltage governor for the AMD Cyan
      Skillfish APU. The daemon continuously samples GPU load, computes a target
      frequency, and adjusts GPU frequency and voltage via SMU mailbox (PCI config space) or kernel sysfs.
    '';

    package = lib.mkPackageOption pkgs "cyan-skillfish-governor-smu" { };

    settings = lib.mkOption rec {
      type = settingsFormat.type;
      default = {
        timing = {
          intervals = {
            sample = 250;
            adjust = 100000;
          };
          ramp-rates = {
            normal = 1;
            burst = 50;
          };
          burst-samples = 60;
          down-events = 5;
        };
        gpu-usage = {
          fix-metrics = true;
          method = "busy-flag";
          flush-every = 10;
        };
        gpu = {
          set-method = "smu";
        };
        dbus = {
          enabled = true;
        };
        frequency-range = {
          min = 1000;
          max = 1850;
        };
        frequency-thresholds = {
          adjust = 10;
        };
        load-target = {
          upper = 0.65;
          lower = 0.50;
        };
        temperature = {
          throttling = 85;
          throttling_recovery = 75;
        };
        safe-points = [
          { frequency = 500;  voltage = 700; }
          { frequency = 1000; voltage = 800; }
          { frequency = 1175; voltage = 850; }
          { frequency = 1500; voltage = 900; }
          { frequency = 1600; voltage = 910; }
          { frequency = 1700; voltage = 920; }
          { frequency = 1850; voltage = 930; }
          { frequency = 2000; voltage = 960; }
        ];
      };
      example = default;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [cfg.package]
      ++ lib.optional (cfg.settings ? dbus && cfg.settings.dbus.enabled)
      pkgs.dbus;

    environment.etc."cyan-skillfish-governor-smu/config.toml".source =
      settingsFormat.generate "cyan-skillfish-governor-config.toml" cfg.settings;

    services.dbus.packages = [cfg.package];

    systemd.services.cyan-skillfish-governor-smu = {
      description = "Cyan Skillfish GPU Governor";
      conflicts = [
        "cyan-skillfish-governor.service"
        "cyan-skillfish-governor-tt.service"
        "oberon-governor.service"
      ];
      wantedBy = ["default.target"];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/cyan-skillfish-governor-smu /etc/cyan-skillfish-governor-smu/config.toml";
        ManagedOOMPreference = "avoid";
        OOMScoreAdjust = -1000;
        Restart = "on-failure";
        RestartSec = "5";
      };
    };
  };
}
