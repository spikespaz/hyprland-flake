{ lib, ... }:
{ config, pkgs, ... }:
let
  cfg = config.wayland.windowManager.hyprland;

  hyprlang = pkgs.callPackage ./devicesFormat.nix { inherit lib; };
  devicesFormat = hyprlang cfg.configFormatOptions;
in {
  options = {
    wayland.windowManager.hyprland.deviceConfig = lib.mkOption {
      type = devicesFormat.type;
      default = { };
      description = lib.mdDoc "\n";
      example = lib.literalExpression "\n";
    };
  };

  config = {
    wayland.windowManager.hyprland.configFile."devices.conf".text =
      devicesFormat.toConfigString cfg.deviceConfig;

    wayland.windowManager.hyprland.config.source =
      [ "${config.xdg.configHome}/hypr/devices.conf" ];
  };
}
