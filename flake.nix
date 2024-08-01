{
  description = ''
    A Nix flake for the Hyprland window manager.
    <https://github.com/hyprwm/hyprland>
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Extensions to `nixpkgs.lib` required by the Hyprlang serializer.
    # <https://github.com/spikespaz/bird-nix-lib>
    bird-nix-lib.url = "github:spikespaz/bird-nix-lib";

    # <https://github.com/nix-systems/nix-systems>
    systems = {
      url = "github:nix-systems/default-linux";
      flake = false;
    };

    # Official `hyprwm` flakes. Re-listed here because you can `follows`
    # this flake's inputs.

    # <https://github.com/hyprwm/Hyprland/blob/main/flake.nix>
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.aquamarine.follows = "aquamarine";
      inputs.hyprcursor.follows = "hyprcursor";
      inputs.hyprlang.follows = "hyprlang";
      inputs.hyprutils.follows = "hyprutils";
      inputs.hyprwayland-scanner.follows = "hyprwayland-scanner";
      inputs.xdph.follows = "xdg-desktop-portal-hyprland";
    };
    # <https://github.com/hyprwm/hyprwayland-scanner/blob/main/flake.nix>
    hyprwayland-scanner = {
      url = "github:hyprwm/hyprwayland-scanner";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # <https://github.com/hyprwm/hyprland-protocols/blob/main/flake.nix>
    hyprland-protocols = {
      url = "github:hyprwm/hyprland-protocols";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # <https://github.com/hyprwm/xdg-desktop-portal-hyprland/blob/master/flake.nix>
    xdg-desktop-portal-hyprland = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprland-protocols.follows = "hyprland-protocols";
      inputs.hyprlang.follows = "hyprlang";
    };
    # <https://github.com/hyprwm/hyprutils/blob/main/flake.nix>
    hyprutils = {
      url = "github:hyprwm/hyprutils";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # <https://github.com/hyprwm/hyprlang/blob/main/flake.nix>
    hyprlang = {
      url = "github:hyprwm/hyprlang";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprutils.follows = "hyprutils";
    };
    # <https://github.com/hyprwm/hyprcursor/blob/main/flake.nix>
    hyprcursor = {
      url = "github:hyprwm/hyprcursor";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprlang";
    };
    # <https://github.com/hyprwm/aquamarine/blob/main/flake.nix>
    aquamarine = {
      url = "github:hyprwm/aquamarine";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprutils.follows = "hyprutils";
      inputs.hyprwayland-scanner.follows = "hyprwayland-scanner";
    };
  };

  outputs = {
    # Prerequisites
    self, nixpkgs, systems, bird-nix-lib
    # Official Hyprland flakes
    , hyprland, hyprwayland-scanner, hyprland-protocols
    , xdg-desktop-portal-hyprland, hyprutils, hyprlang, hyprcursor, aquamarine
    }:
    let
      inherit (self) lib;
      extendLib = lib:
        if lib ? bird && lib ? hl then
          lib
        else
          lib.extend (lib.composeManyExtensions [
            bird-nix-lib.lib.overlay
            (import ./lib)
          ]);
      eachSystem = lib.genAttrs (import systems);
    in {
      lib = extendLib nixpkgs.lib // {
        overlay = import ./lib;
        inherit extendLib;
      };

      # All input flake packages (those that have them) are merged into this
      # flake's `packages` output. The merge will override derivation attributes
      # according to the order the flake inputs are listed here.
      #
      # For example, two packages export `xdg-desktop-portal-hyprland`,
      # being the flake of the same name and `hyprland`. Since the input
      # `hyprland` is listed before `xdg-desktop-portal-hyprland`,
      # the package from the latter flake will appear in the output here.
      # Generally, this is the reverse-order of which overlays would be applied.
      # This order does have meaning, but in general makes no difference
      # as long as the inputs of each flake follow the correct channels.
      #
      # Ideally, we would `inherit` every single package from each input
      # individually, but this would be very tedious to maintain.
      # This is easier to maintain this "list of flakes which have packages".
      packages = let
        fromInputs = [
          hyprland
          hyprwayland-scanner
          hyprland-protocols
          xdg-desktop-portal-hyprland
          hyprutils
          hyprlang
          hyprcursor
          aquamarine
        ];
      in eachSystem (system:
        (lib.foldl' (packages: input: packages // input.packages.${system}) { }
          fromInputs) // {
            default = self.packages.${system}.hyprland;
          });

      # See the comment for the `packages` output above,
      # this output is merged together in the same way.
      overlays = let
        fromInputs = [
          hyprland
          hyprwayland-scanner
          hyprland-protocols
          xdg-desktop-portal-hyprland
          hyprlang
          hyprcursor
          aquamarine
        ];
        # Currently this default overlay is identical to that of the `hyprland`
        # flake. It is redefined here because the `default` overlay from other
        # flakes are dropped.
        #
        # It is expected that other flakes provide a `default` overlay that is
        # aggregate of others, in which case, it should not be re-exported
        # for this flake, or it is an alias to a package overlay
        # (which would already be present in this merged set).
        default = with self.overlays;
          lib.composeManyExtensions [ hyprland-packages hyprland-extras ];
      in lib.foldl' (overlays: input: overlays // input.overlays) { } fromInputs
      // {
        inherit default;
      };

      homeManagerModules = {
        default = self.homeManagerModules.hyprland;
        hyprland = import ./hm-module self;
      };

      checks = eachSystem (system:
        let pkgs = import nixpkgs { localSystem = system; };
        in {
          check-formatting = pkgs.stdenvNoCC.mkDerivation {
            name = "check-formatting";
            src = ./.;
            phases = [ "checkPhase" "installPhase" ];
            doCheck = true;
            nativeCheckInputs = [ pkgs.nixfmt-classic ];
            checkPhase = ''
              cd $src
              echo 'Checking Nix code formatting with Nixfmt:'
              nixfmt --check .
            '';
            installPhase = "touch $out";
          };
        });

      formatter =
        eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-classic);

      # Should be kept in sync with upstream.
      # <https://github.com/hyprwm/Hyprland/blob/1925e64c21811ce76e5059d7a063f968c2d3e98c/flake.nix#L98-L101>
      nixConfig = {
        extra-substituters = [ "https://hyprland.cachix.org" ];
        extra-trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };
    };
}
