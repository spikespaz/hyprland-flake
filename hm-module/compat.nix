{ lib, ... }:
{ config, pkgs, ... }:
let
  inherit (lib) types;

  cfg = config.wayland.windowManager.hyprland;
in {
  options = {
    wayland.windowManager.hyprland = {
      fufexan.enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable compatibility for Home Manager modules which depend on Fufexan's HM-native module.
        '';
      };

      settings.source = lib.mkOption {
        type = with types; listOf (either path package);
        default = [ ];
        internal = true;
        visible = false;
        description = ''
          Please use {option}`wayland.windowManager.hyprland.config.source` instead!
        '';
      };
    };
  };
  config = lib.mkIf cfg.fufexan.enable {
    wayland.windowManager.hyprland.config.source = cfg.settings.source;
  };
}
