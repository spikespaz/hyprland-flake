self:
args@{ ... }:
let lib = self.lib.extendLib args.lib;
in {
  disabledModules = [
    # module in Home Manager conflicts with this one
    "services/window-managers/hyprland.nix"
  ];

  imports = map (nix: import nix { inherit self lib; }) [
    ./config.nix
    ./compat.nix
    ./events.nix
    ./environment.nix
    ./rules.nix # windowrulev2, layerrule, workspace
    ./animations.nix
    ./keybinds.nix
    ./monitors.nix
    ./devices.nix
  ];
}
