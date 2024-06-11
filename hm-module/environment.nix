{ lib, ... }:
{ config, pkgs, ... }:
let
  inherit (lib) types;

  cfg = config.wayland.windowManager.hyprland;
in {
  options = {
    wayland.windowManager.hyprland = {
      systemdIntegration = lib.mkOption {
        type = types.bool;
        default = pkgs.stdenv.isLinux;
        description = lib.mdDoc ''
          Whether to enable {file}`hyprland-session.target` on
          hyprland startup. This links to {file}`graphical-session.target`.
          Some important environment variables will be imported to systemd
          and dbus user environment before reaching the target, including:
          - {env}`DISPLAY`
          - {env}`HYPRLAND_INSTANCE_SIGNATURE`
          - {env}`WAYLAND_DISPLAY`
          - {env}`XDG_CURRENT_DESKTOP`
        '';
      };

      environment = lib.mkOption {
        type = with types; lazyAttrsOf (oneOf [ str path int float ]);
        default = { };
        description = lib.mdDoc ''
          Set environment variables for the Hyprland session,
          similar to {option}`home.sessionVariables`.

          This is a convenience option that sets
          {option}`wayland.windowManager.hyprland.config.env`.

          Environment variables here are not used in any session other
          than Hyprland.
        '';
      };

      recommendedEnvironment = lib.mkOption {
        type = types.bool;
        default = pkgs.stdenv.isLinux;
        description = lib.mdDoc ''
          Whether to set some recommended environment variables.

          These are specific to the Hyprland session and are not exported
          through {option}`home.sessionVariables`.

          This is because those variables would be used by all sessions,
          graphical or not, no matter the specific window manager.
        '';
      };

      dbusEnvironment = lib.mkOption {
        type = types.listOf types.singleLineStr;
        default = [
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "HYPRLAND_INSTANCE_SIGNATURE"
          "XDG_CURRENT_DESKTOP"
        ];
        description = lib.mkDoc ''
          Names of environment variables to be exported for
          all D-Bus session services.

          These variables will also be exported for systemd if
          {option}`wayland.windowManager.hyprland.systemdIntegration`
          is enabled.
        '';
      };

      extraDbusEnvironment = lib.mkOption {
        type = types.listOf types.singleLineStr;
        default = [ ];
        description = lib.mdDoc ''
          Extra names of environment variables to be added to
          {option}`wayland.windowManager.hyprland.dbusEnvironment`.

          It is recommended to use this option instead of modifying
          the option mentioned above.
        '';
      };
    };
  };

  config = lib.mkMerge [
    {
      wayland.windowManager.hyprland.config.exec_once = lib.mkOrder 10 [
        "${pkgs.dbus}/bin/dbus-update-activation-environment ${
          lib.concatStringsSep " "
          ((lib.optional cfg.systemdIntegration "--systemd")
            ++ cfg.dbusEnvironment ++ cfg.extraDbusEnvironment)
        }"
      ];

      wayland.windowManager.hyprland.config.env =
        lib.mapAttrsToList (name: value: "${name},${toString value}")
        cfg.environment;
    }
    (lib.mkIf cfg.systemdIntegration {
      systemd.user.targets.hyprland-session = {
        Unit = {
          Description = "hyprland compositor session";
          Documentation = [ "man:systemd.special(7)" ];
          BindsTo = [ "graphical-session.target" ];
          Wants = [ "graphical-session-pre.target" ];
          After = [ "graphical-session-pre.target" ];
        };
      };
      wayland.windowManager.hyprland.config.exec_once =
        lib.mkOrder 11 [ "systemctl --user start hyprland-session.target" ];
    })
    (lib.mkIf cfg.recommendedEnvironment {
      wayland.windowManager.hyprland.environment = { NIXOS_OZONE_WL = 1; };
    })
  ];
}
