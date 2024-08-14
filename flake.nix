{
  description = ''
    A Nix flake for the Hyprland window manager.
    <https://github.com/hyprwm/hyprland>
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # <https://github.com/nix-systems/nix-systems>
    systems = {
      url = "github:nix-systems/default-linux";
      flake = false;
    };

    # Extensions to `nixpkgs.lib` required by the Hyprlang serializer.
    # <https://github.com/spikespaz/bird-nix-lib>
    bird-nix-lib.url = "github:spikespaz/bird-nix-lib";

    # Official `hyprwm` flakes. Re-listed here because you can `follows`
    # this flake's inputs.

    # <https://github.com/hyprwm/Hyprland/blob/main/flake.nix>
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    # <https://github.com/hyprwm/hyprwayland-scanner/blob/main/flake.nix>
    hyprwayland-scanner.url = "github:hyprwm/hyprwayland-scanner";
    # <https://github.com/hyprwm/hyprland-protocols/blob/main/flake.nix>
    hyprland-protocols.url = "github:hyprwm/hyprland-protocols";
    # <https://github.com/hyprwm/xdg-desktop-portal-hyprland/blob/master/flake.nix>
    xdph.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    # <https://github.com/hyprwm/hyprutils/blob/main/flake.nix>
    hyprutils.url = "github:hyprwm/hyprutils";
    # <https://github.com/hyprwm/hyprlang/blob/main/flake.nix>
    hyprlang.url = "github:hyprwm/hyprlang";
    # <https://github.com/hyprwm/hyprcursor/blob/main/flake.nix>
    hyprcursor.url = "github:hyprwm/hyprcursor";
    # <https://github.com/hyprwm/aquamarine/blob/main/flake.nix>
    aquamarine.url = "github:hyprwm/aquamarine";
  };

  outputs = {
    # Prerequisites
    self, nixpkgs, systems, bird-nix-lib
    # Official Hyprland flakes
    , hyprland, hyprwayland-scanner, hyprland-protocols
    , xdph, hyprutils, hyprlang, hyprcursor, aquamarine
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
      hyprwmInputs = [
        hyprland
        hyprwayland-scanner
        hyprland-protocols
        xdph
        hyprutils
        hyprlang
        hyprcursor
        aquamarine
      ];
      hyprwmPackages = eachSystem (system:
        lib.filterAttrs
        (name: _: !(name == "default" || lib.hasSuffix "-cross" name))
        (lib.foldl' (packages: input: packages // input.packages.${system}) { }
          hyprwmInputs));
      hyprwmOverlays = lib.flip removeAttrs [ "default" ]
        (lib.foldl' (overlays: input: overlays // input.overlays) { }
          hyprwmInputs);
      pkgsFor = eachSystem (system:
        import nixpkgs {
          localSystem.system = system;
          overlays = lib.attrValues hyprwmOverlays;
        });
    in {
      lib = extendLib nixpkgs.lib // {
        overlay = import ./lib;
        # Usage:
        # `lib = inputs.hyprnix.lib.extendLib inputs.nixpkgs.lib`
        inherit extendLib;
      };

      # The packages here are aggregated from Hyprwm input flake's `packages` output.
      # Cross-compiled packages are removed.
      packages = eachSystem (system:
        let
          overlayPackages = lib.mapAttrs (name: _: pkgsFor.${system}.${name})
            hyprwmPackages.${system};
        in overlayPackages // { default = self.packages.${system}.hyprland; });

      # Overlays aggregated from Hyprwm flakes' `overlays` outputs.
      overlays = let
        default = with self.overlays;
          lib.composeManyExtensions [ hyprland-packages hyprland-extras ];
      in hyprwmOverlays // { inherit default; };

      homeManagerModules = {
        default = self.homeManagerModules.hyprland;
        hyprland = import ./hm-module self;
      };

      checks = eachSystem (system:
        self.packages.${system} // {
          check-formatting = pkgsFor.${system}.stdenvNoCC.mkDerivation {
            name = "check-formatting";
            src = ./.;
            phases = [ "checkPhase" "installPhase" ];
            doCheck = true;
            nativeCheckInputs = [ self.formatter.${system} ];
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
