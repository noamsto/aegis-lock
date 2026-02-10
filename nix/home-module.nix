{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.aegis-lock;
in
{
  options.programs.aegis-lock = {
    enable = lib.mkEnableOption "Aegis Lock - standalone Wayland lockscreen";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The aegis-lock package to use";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Aegis Lock configuration (written to config.json)";
    };

    pamConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        System PAM config name to use instead of generated per-user configs.
        When set, AEGIS_PAM_CONFIG env var is set to this value.
        For NixOS, you typically set this to "aegis-lock" and configure
        security.pam.services.aegis-lock in your NixOS config.
      '';
    };

    fingerprint = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable fingerprint authentication support";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Generate config.json if settings provided
    xdg.configFile."aegis-lock/config.json" = lib.mkIf (cfg.settings != { }) {
      text = builtins.toJSON cfg.settings;
    };

    # Generate PAM configs (when not using system PAM)
    xdg.configFile."aegis-lock/pam/fingerprint-only.conf" =
      lib.mkIf (cfg.pamConfig == null && cfg.fingerprint.enable)
        {
          text = ''
            auth sufficient pam_fprintd.so timeout=-1 max-tries=-1
            auth sufficient /run/current-system/sw/lib/security/pam_fprintd.so timeout=-1 max-tries=-1
            auth required pam_deny.so
          '';
        };

    xdg.configFile."aegis-lock/pam/password-only.conf" = lib.mkIf (cfg.pamConfig == null) {
      text = ''
        auth required pam_unix.so
      '';
    };

    xdg.configFile."aegis-lock/pam/other" = lib.mkIf (cfg.pamConfig == null) {
      text = ''
        auth required pam_deny.so
      '';
    };

    # Set environment variable for system PAM config
    systemd.user.sessionVariables = lib.mkIf (cfg.pamConfig != null) {
      AEGIS_PAM_CONFIG = cfg.pamConfig;
    };
  };
}
