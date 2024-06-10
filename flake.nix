{
  description = ''
    A Nix flake for the Hyprland window manager.
    <https://github.com/hyprwm/hyprland>
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
      url = "github:hyprwm/hyprland";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
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
    # <https://github.com/hyprwm/xdg-desktop-portal-hyprland/blob/main/flake.nix>
    xdg-desktop-portal-hyprland = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprland-protocols.follows = "hyprland-protocols";
      inputs.hyprlang.follows = "hyprlang";
    };
    # <https://github.com/hyprwm/hyprlang/blob/main/flake.nix>
    hyprlang = {
      url = "github:hyprwm/hyprlang";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # <https://github.com/hyprwm/hyprcursor/blob/main/flake.nix>
    hyprcursor = {
      url = "github:hyprwm/hyprcursor";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprlang";
    };
  };

  outputs = {
    # prereq
    self, nixpkgs, systems, bird-nix-lib
    # official hyprwm flakes
    , hyprland, hyprwayland-scanner, hyprland-protocols
    , xdg-desktop-portal-hyprland, hyprlang, hyprcursor }:
    let
      inherit (self) lib;
      eachSystem = lib.genAttrs (import systems);
    in {
      lib = let
        overlay = nixpkgs.lib.composeManyExtensions [
          bird-nix-lib.lib.overlay
          (import ./lib)
        ];
      in nixpkgs.lib.extend overlay // { inherit overlay; };

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
          hyprlang
          hyprcursor
        ];
      in eachSystem (system:
        (lib.foldl' (packages: input: packages // input.packages.${system}) { }
          fromInputs) // {
            default = hyprland.packages.${system}.hyprland;
          });

      # The most important overlys are re-exported from this flake.
      # This flake's `default` overlay contains minimum required overlays.
      # Other overlays can be accessed through
      # `inputs.hyprland-nix.inputs.<flake-name>.overlays.<overlay-name>`.
      overlays = {
        inherit (hyprland.overlays)
          hyprland-packages hyprland-extras wlroots-hyprland;
        inherit (xdg-desktop-portal-hyprland.overlays)
          xdg-desktop-portal-hyprland hyprland-share-picker;
      } // {
        default = lib.composeManyExtensions
          (with self.overlays; [ hyprland-packages hyprland-extras ]);
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
