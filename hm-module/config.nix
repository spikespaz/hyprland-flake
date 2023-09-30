self:
args@{ config, lib, pkgs, ... }:
let
  inherit (self.lib) lib;
  inherit (lib) types;

  args' = args // { inherit lib; };

  cfg = config.wayland.windowManager.hyprland;
  cfgPath = "config.wayland.windowManager.hyprland";

  defaultPackage = self.inputs.hyprland-git.packages.${pkgs.system}.hyprland;

  configFormat = (import ./configFormat.nix args') cfg.configFormatOptions;
  configRenames = import ./configRenames.nix args';

  toConfigString = attrs:
    lib.pipe attrs [
      (with configRenames; renameAttrs renames.from renames.to)
      configFormat.toConfigString
    ];
in {
  options = {
    wayland.windowManager.hyprland = {
      enable = lib.mkEnableOption (lib.mdDoc ''
        Whether to install the Hyprland package and generate configuration files.

        ${defaultPackage.meta.description}

        See <${defaultPackage.meta.homepage}> for more information.
      '');
      package = lib.mkOption {
        type = types.package;
        default = defaultPackage;
        example = lib.literalExpression ''
          pkgs.hyprland # if you use the overlay
        '';
        description = lib.mdDoc ''
          Hyprland package to use. The options in {option}`xwayland` and
          {option}`nvidiaPatches` will be applied to the package
          specified here via an override.

          Defaults to the one provided by the flake. Set it to
          {package}`pkgs.hyprland` to use the one provided by nixpkgs or
          if you have an overlay.

          Set to null to not add any Hyprland package to your path. This should
          be done if you want to use the NixOS module to install Hyprland.
        '';
      };

      finalPackage = lib.mkOption {
        type = types.package;
        readOnly = true;
        description = lib.mdDoc ''
          The final Hyprland packge that should be used in other parts of configuration.
          This is the result after applying overrides which are enabled/disabled/specified
          by other options of this module (for example, `xwayland.enable` or `nvidiaPatches`).
        '';
      };

      # plugins = lib.mkOption {
      #   type = types.listOf (types.either types.package types.path);
      #   default = [];
      #   description = lib.mdDoc ''
      #     List of paths or packages to install as Hyprland plugins.
      #   '';
      # };

      xwayland.enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          Enable XWayland.
        '';
      };

      nvidiaPatches = lib.mkOption {
        type = lib.types.bool;
        default = false;
        defaultText = lib.literalExpression "false";
        example = lib.literalExpression "true";
        description = lib.mdDoc ''
          Patch wlroots for better Nvidia support.
        '';
      };

      reloadConfig = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc ''
          If enabled, automatically tell Hyprland to reload configuration
          after activating a new Home Manager generation.

          Note, this option is different from
          `${cfgPath}.config.misc.disable_autoreload`,
          which disables Hyprland's filesystem watch.
        '';
      };

      ### CONFIG ###

      config = lib.mkOption {
        type = configFormat.type;
        default = { };
        description = lib.mdDoc ''
          Hyprland config attributes.
          These will be serialized to lines of text,
          included in {path}`$XDG_CONFIG_HOME/hypr/hyprland.conf`.
        '';
      };

      extraConfig = lib.mkOption {
        type = with types; nullOr lines;
        default = null;
        description = lib.mdDoc ''
          Extra configuration lines to append to the bottom of
          `~/.config/hypr/hyprland.conf`.
        '';
      };

      configOrder = lib.mkOption {
        type = types.listOf (types.listOf types.singleLineStr);
        default = [
          [ "env" ]

          [ "exec-once" ]
          [ "exec" ]

          [ "source" ]

          [ "monitor" ]
          [ "workspace" ]

          [ "dwindle" ]
          [ "master" ]
          [ "general" ]
          [ "input" ]
          [ "binds" ]
          [ "gestures" ]
          [ "decoration" ]
          [ "animations" ]

          [ "blurls" ]
          [ "windowrule" ]
          [ "layerrule" ]
          [ "windowrulev2" ]

          [ "misc" ]
          [ "debug" ]

          [ "animations" "bezier" ]
          [ "animations" "animation" ]
        ];
        description = lib.mdDoc ''
          An ordered list of attribute paths
          to determine sorting order of config section lines.

          This is necessary in some cases, namely where `bezier` must be defined
          before it can be used in `animation`.
        '';
      };

      configFormatOptions = {
        sortPred = lib.mkOption {
          type = types.anything;
          # type = with types; functionTo (functionTo bool);
          default = a: b:
            let
              ia = lib.indexOfDefault (-1) a cfg.configOrder;
              ib = lib.indexOfDefault (-1) b cfg.configOrder;
            in ia < ib;
          description = lib.mdDoc ''
            The predicate with which to sort nodes recursively.
            Given two node paths, `prev` and `next`,
            return `true` for "ascend" and `false` for descend.
          '';
        };
        indentChars = lib.mkOption {
          type = types.strMatching "([ \\t]+)";
          default = "    ";
          description = lib.mdDoc ''
            Characters to use for each indent level,
          '';
        };
        spaceAroundEquals = lib.mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc ''
            Whether to have spaces before and after an equals `=` operator.
          '';
        };
        lineBreakPred = lib.mkOption {
          type = types.anything;
          # type = with types; functionTo (functionTo bool);
          default = prev: next:
            let
              inherit (configFormat.lib) nodeType isRepeatNode isSectionNode;
              betweenDifferent = nodeType prev != nodeType next;
              betweenRepeats = isRepeatNode prev && isRepeatNode next;
              betweenSections = isSectionNode prev && isSectionNode next;
            in prev != null
            && (betweenDifferent || betweenRepeats || betweenSections);
          description = lib.mdDoc ''
            The predicate with which to determine where to insert line breaks.
            Return `true` to add a break, `false` to continue.

            Use functions from {path}`configFormat.nix` to test node types.
          '';
          defaultText = lib.literalExpression ''
            prev: next:
              let
                configFormat = (import ./configFormat.nix args') cfg.configFormatOptions;
                inherit (configFormat.lib) nodeType isRepeatNode isSectionNode;
                betweenDifferent = nodeType prev != nodeType next;
                betweenRepeats = isRepeatNode prev && isRepeatNode next;
                betweenSections = isSectionNode prev && isSectionNode next;
              in prev != null
              && (betweenDifferent || betweenRepeats || betweenSections)
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      wayland.windowManager.hyprland.finalPackage = cfg.package.override {
        enableXWayland = cfg.xwayland.enable;
        inherit (cfg) nvidiaPatches;
      };
      home.packages = [ cfg.finalPackage ]
        ++ lib.optional cfg.xwayland.enable pkgs.xwayland;
    }
    (lib.mkIf (cfg.config != null) {
      wayland.windowManager.hyprland.configFile."hyprland.conf".text =
        lib.mkOrder 500 (toConfigString cfg.config);
    })
    (lib.mkIf (cfg.extraConfig != null) {
      wayland.windowManager.hyprland.configFile."hyprland.conf".text =
        lib.mkOrder 900 cfg.extraConfig;
    })
    (lib.mkIf cfg.reloadConfig {
      wayland.windowManager.hyprland.config.misc.disable_autoreload =
        lib.mkDefault true;

      xdg.configFile."hypr".onChange = ''
        (
          shopt -s nullglob
          for instance in /tmp/hypr/*; do
            HYPRLAND_INSTANCE_SIGNATURE=''${instance##*/}
            response="$(${cfg.finalPackage}/bin/hyprctl reload config-only 2>&1)"
            [[ $response =~ ^ok ]] && \
              echo "Hyprland instance reloaded: $HYPRLAND_INSTANCE_SIGNATURE"
          done
        )
      '';
    })
  ]);
}
