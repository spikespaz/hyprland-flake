self:
{ ... }:
let
in {
  disabledModules = [
    # module in Home Manager conflicts with this one
    "services/window-managers/hyprland.nix"
  ];

  imports = map (nix: import nix self) [
    ./config.nix
    ./events.nix
    ./environment.nix
    ./rules.nix # windowrulev2, layerrule, workspace
    ./animations.nix
    ./keybinds.nix
    ./monitors.nix
  ];
}
