self:
{ config, ... }:
let
  inherit (self.lib) lib;
  inherit (lib) types;

  cfg = config.wayland.windowManager.hyprland.monitors;

  # See docs of option `transform`.
  transformEnum = {
    "Normal" = 0;
    "Degrees90" = 1;
    "Degrees180" = 2;
    "Degrees270" = 3;
    "Flipped" = 4;
    "FlippedDegrees90" = 5;
    "FlippedDegrees180" = 6;
    "FlippedDegrees270" = 7;
  };
  transformEnumType = types.enum
    (builtins.attrValues transformEnum ++ builtins.attrNames transformEnum);

  # For position and resolution.
  point2DType = numType:
    types.submodule {
      options = {
        x = lib.mkOption {
          type = numType;
          description =
            "The X-coordinate of a point, or the width of a rectangle.";
        };
        y = lib.mkOption {
          type = numType;
          description =
            "The Y-coordinate of a point, or the height of a rectangle.";
        };
      };
    };
in {
  options = {
    wayland.windowManager.hyprland.monitors = lib.mkOption {
      type = types.attrsOf (types.submodule ({ config, ... }: {
        options = {
          name = lib.mkOption {
            type = types.nullOr types.singleLineStr;
            default = null;
            description = ''
              The name of the monitor as shown in the output of
              `hyprctl monitors`, for example `eDP-1` or `HDMI-A-1`.

              This option is mutually exclusive with {option}`description`.
            '';
          };
          description = lib.mkOption {
            type = types.nullOr types.singleLineStr;
            default = null;
            description = ''
              If your monitor "names" are non-deterministic
              (e.g., sometimes a monitor is `DP-5`, other times `DP-6`),
              you can specify this option instead.

              This option is mutually exclusive with {option}`name`.
            '';
          };
          position = lib.mkOption {
            type = types.either (point2DType types.ints.unsigned)
              (types.enum [ "auto" ]);
            default = "auto";
            description = ''
              The position of the monitor as `{ x, y }` attributes.

              This is not the same as {option}`position` which is a
              string or an enum string.
            '';
          };
          resolution = lib.mkOption {
            type = types.either (point2DType types.ints.positive)
              (types.enum [ "preferred" "highrr" "highres" ]);
            default = "preferred";
            description = ''
              The physical size of the display as `{ x, y }` attributes.

              This is not the same as {option}`option` which is a
              string or an enum string.
            '';
          };
          scale = lib.mkOption {
            type = types.float;
            default = 1.0;
            description = ''
              The fractional scaling factor to use for Wayland-native programs.
              The virtual size of the display will be each dimension divided by
              this float. For example, the virtual size of a monitor with a physical
              size of 2880x1800 pixels would be 1920x1200 virtual pixels.
            '';
          };
          refreshRate = lib.mkOption {
            type = types.nullOr (types.either types.ints.positive types.float);
            default = null;
            description = ''
              The refresh rate of the monitor, if unspecified will choose
              a default mode for your specified resolution.
            '';
          };
          bitdepth = lib.mkOption {
            type = types.enum [ 8 10 ];
            default = 8;
            description = ''
              The color bit-depth of the monitor (8-bit or 10-bit color).
            '';
          };
          transform = lib.mkOption {
            type = transformEnumType;
            default = "Normal";
            description = ''
              Attribute names (enum identifiers) and values (repr) from the
              following ~~enum~~ attribute set are accepted as variants
              in this option `lib.types.enum`.

              ```nix
              ${lib.generators.toPretty { multiline = true; } transformEnum}
              ```
            '';
          };
          mirror = lib.mkOption {
            type = types.nullOr types.singleLineStr;
            default = null;
            description = "The name of the monitor to mirror.";
            example = lib.mdDoc ''
              The "name" of the monitor is after the display protocol
              it is connected with: `eDP-1`, `HDMI-A-1`, `DP-5`, `DP-6`, etc.
            '';
          };

          size = lib.mkOption {
            type = types.nullOr (point2DType types.float);
            description = ''
              The virtual display size after scaling,
              indended for use in recursive Nix configurations.
            '';
          };
          keywordParams = lib.mkOption {
            type = types.listOf types.singleLineStr;
            internal = true;
          };
        };

        config =
          #
          # assert lib.assertMsg
          #   (config.name == null && config.description == null) ''
          #     Neither `name` nor `description` have been set,
          #     please specify one of these options.
          #   '';
          # assert lib.assertMsg
          #   (lib.xor (config.name == null) (config.description == null)) ''
          #     The options `name` and `description` are mutually exclusive,
          #     please specify exactly one of them.
          #   '';
          let
            positionIsPoint =
              (point2DType types.ints.unsigned).check config.position;
            resolutionIsPoint =
              (point2DType types.ints.positive).check config.resolution;
          in {
            size = lib.mkIf resolutionIsPoint {
              x = config.resolution.x / config.scale;
              y = config.resolution.y / config.scale;
            };

            keywordParams = lib.concatLists [
              # The name or description to match for this monitor profile.
              # See the asserts above, only one will be present in configuration.
              (lib.optional (config.name != null) config.name)
              (lib.optional (config.description != null)
                "desc:${config.description}")

              # The resolution in `WIDTHxHEIGHT@REFRESH`, with `@REFRESH` optionally.
              (lib.optional resolutionIsPoint
                "${toString config.resolution.x}x${
                  toString config.resolution.y
                }${
                  lib.optionalString (config.refreshRate != null)
                  "@${toString config.refreshRate}"
                }")
              # The resolution verbatim if it is an enum string.
              (lib.optional (!resolutionIsPoint) config.resolution)

              # The position in `XxY` format if it is a point.
              (lib.optional positionIsPoint
                "${toString config.position.x}x${toString config.position.y}")
              # The position verbatim if it is an enum string.
              (lib.optional (!positionIsPoint) config.position)

              #
              [ (toString config.scale) ]
              [ "bitdepth" (toString config.bitdepth) ]
              [
                "transform"
                (if lib.isInt config.transform then
                  toString config.transform
                else
                  toString transformEnum.${config.transform})
              ]
              (lib.optionals (config.mirror != null) [ "mirror" config.mirror ])
              #
            ];
          };
      }));

      description = ''
        Monitors to configure. The attribute name is not used in the
        Hyprland configuration, but is a convenience for recursive Nix.

        The "name" the monitor will have (the connector, not make and model)
        is specified in the `name` attribute for the monitor.
        It is not the attribute name of the monitor in *this* parent set.
      '';

      example = lib.literalExpression ''
        (with config.wayland.windowManager.hyprland.monitors; {
          # The attribute name `internal` is for usage in recursive Nix.
          internal = {
            name = "eDP-1";
            pos = "auto"; # `auto` is default
            size = "preferred"; # `preferred` is default
            bitdepth = 10;
          };
        })
      '';

      default = { };
    };
  };

  config = {
    wayland.windowManager.hyprland.config.monitor = lib.mapAttrsToList
      (attrName: monitor: lib.concatStringsSep "," monitor.keywordParams) cfg;
  };
}
