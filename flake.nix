{
  description = ''
    A Nix flake for the Hyprland window manager.
    <https://github.com/hyprwm/hyprland>
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # <https://github.com/nix-systems/nix-systems>
    systems.url = "github:nix-systems/default-linux";

    # Official `hyprwm` flakes. Re-listed here because you can `follows`
    # this flake's inputs.
    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-protocols = {
      url = "github:hyprwm/hyprland-protocols";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-xdph = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprland-protocols.follows = "hyprland-protocols";
    };

    nixfmt.url = "github:serokell/nixfmt";
    bird-nix-lib.url = "github:spikespaz/bird-nix-lib";
  };

  outputs = inputs@{ self, nixpkgs, systems, hyprland, hyprland-protocols
    , hyprland-xdph, ... }:
    let
      lib' = nixpkgs.lib.pipe nixpkgs.lib [
        (l: l.extend self.inputs.bird-nix-lib.lib.overlay)
        (l: l.extend (import "${self}/lib"))
      ];
    in let
      lib = lib';

      eachSystem = lib.genAttrs (import systems);
    in {
      lib = {
        # The overlays are combined because members of this flake's `lib`
        # may not work without `bird-nix-lib`.
        overlay = lib.bird.mkJoinedOverlays [
          self.inputs.bird-nix-lib.lib.overlay
          (import ./lib)
        ];
        # Each module in this flake inherits the final `lib` exposed here.
        lib = nixpkgs.lib.extend self.lib.overlay;
      };

      # Packages have priority from right-to-left. Packages from the rightmost
      # attributes will replace those with the same name on the accumulated left.
      # This is done specifically for when inputs of `hyprland-xdph`
      # and `hyprland` diverge, packages from `hyprland-xdph` are chosen.
      packages = eachSystem (system:
        hyprland.packages.${system} // hyprland-xdph.packages.${system} // {
          default = hyprland.packages.${system}.hyprland;
        });

      # The most important overlys are re-exported from this flake.
      # This flake's `default` overlay contains minimum required overlays.
      # Other overlays can be accessed through
      # `inputs.hyprland-nix.inputs.<flake-name>.overlays.<overlay-name>`.
      overlays = {
        inherit (hyprland.overlays)
          hyprland-packages hyprland-extras wlroots-hyprland;
        inherit (hyprland-xdph.overlays)
          xdg-desktop-portal-hyprland hyprland-share-picker;
      } // {
        default = lib.bird.mkJoinedOverlays
          (with self.overlays; [ hyprland-packages hyprland-extras ]);
      };

      homeManagerModules = lib.importDir' ./hm-modules null // {
        default = self.homeManagerModules.hyprland;
      };

      checks = eachSystem (system:
        let pkgs = import nixpkgs { localSystem = system; };
        in {
          check-formatting = pkgs.stdenvNoCC.mkDerivation {
            name = "check-formatting";
            src = ./.;
            phases = [ "checkPhase" "installPhase" ];
            doCheck = true;
            nativeCheckInputs = [ inputs.nixfmt.packages.${system}.default ];
            checkPhase = ''
              cd $src
              echo 'Checking Nix code formatting with Nixfmt:'
              nixfmt --check .
            '';
            installPhase = "touch $out";
          };
        });

      formatter = eachSystem (system: inputs.nixfmt.packages.${system}.default);

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
