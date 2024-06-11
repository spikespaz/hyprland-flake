{ self, lib, ... }:
{ config, pkgs, ... }:
let
  inherit (lib) types;
  inherit (lib.hyprnix.types) configFile;

  cfg = config.wayland.windowManager.hyprland;

  defaultPackage = self.packages.${pkgs.system}.hyprland;

  hyprlang = pkgs.callPackage ./configFormat.nix { inherit lib; };
  configRenames = import ./configRenames.nix { inherit lib; };
  configFormat =
    hyprlang (cfg.configFormatOptions // { inherit (cfg) configOrder; });

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

      plugins = lib.mkOption {
        type = types.listOf (types.either types.package types.path);
        default = [ ];
        description = lib.mdDoc ''
          List of paths or packages to install as Hyprland plugins.
        '';
      };

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

          Note, this option is different from {option}`misc.disable_autoreload`,
          which disables Hyprland's filesystem watch.
        '';
      };

      ### CONFIG ###

      configFile = lib.mkOption {
        type = types.attrsOf (configFile pkgs "${config.xdg.configHome}/hypr");
        default = { };
        description = lib.mdDoc ''
          Configuration files and directories to link in the Hyprland config directory.
          This is an attribute set of file descriptions similar to
          {option}`xdg.configFile`, except relative to {path}`$XDG_CONFIG_HOME/hypr`.

          If necessary, you may set {option}`xdg.configFile."hypr".recursive = true`.
        '';
      };

      configPackage = lib.mkOption {
        type = types.package;
        readOnly = true;
      };

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
        # TODO move this type to configFormat
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
          [ "cursor" ]
          [ "input" ]
          [ "input" "touchpad" ]
          [ "input" "touchdevice" ]
          [ "input" "tablet" ]
          [ "device:.*" ]
          [ "binds" ]
          [ "gestures" ]
          [ "group" ]
          [ "group" "groupbar" ]
          [ "decoration" ]
          [ "animations" ]
          [ "animations" "bezier" ]
          [ "animations" "animation" ]

          [ "plugin" ]

          [ "blurls" ]
          [ "windowrule" ]
          [ "layerrule" ]
          [ "windowrulev2" ]

          [ "misc" ]
          [ "xwayland" ]
          [ "debug" ]
        ];
        description = lib.mdDoc ''
          An ordered list of attribute paths
          to determine sorting order of config section lines.

          This is necessary in some cases, namely where `bezier` must be defined
          before it can be used in `animation`.
        '';
      };

      configFormatOptions = {
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

        ## TODO Replace this with boolean flag options.
        ## Asking a novice to build a predicate just to adjust some spacing
        ## is too much, and this can be more parametric.
        # lineBreakPred = lib.mkOption {
        #   type = types.anything;
        #   # type = with types; functionTo (functionTo bool);
        #   default = prev: next:
        #     let
        #       inherit (configFormat.lib) nodeType isRepeatNode isSectionNode;
        #       betweenDifferent = nodeType prev != nodeType next;
        #       betweenRepeats = isRepeatNode prev && isRepeatNode next;
        #       betweenSections = isSectionNode prev && isSectionNode next;
        #     in prev != null
        #     && (betweenDifferent || betweenRepeats || betweenSections);
        #   description = lib.mdDoc ''
        #     The predicate with which to determine where to insert line breaks.
        #     Return `true` to add a break, `false` to continue.

        #     Use functions from {path}`configFormat.nix` to test node types.
        #   '';
        #   defaultText = lib.literalExpression ''
        #     prev: next:
        #       let
        #         configFormat = (import ./configFormat.nix args') cfg.configFormatOptions;
        #         inherit (configFormat.lib) nodeType isRepeatNode isSectionNode;
        #         betweenDifferent = nodeType prev != nodeType next;
        #         betweenRepeats = isRepeatNode prev && isRepeatNode next;
        #         betweenSections = isSectionNode prev && isSectionNode next;
        #       in prev != null
        #       && (betweenDifferent || betweenRepeats || betweenSections)
        #   '';
        # };
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
    {
      wayland.windowManager.hyprland.configPackage = pkgs.symlinkJoin {
        name = "hyprland-config";
        paths = lib.mapAttrsToList (_: file: file.source) cfg.configFile;
      };
    }
    (lib.mkIf cfg.enable { xdg.configFile."hypr".source = cfg.configPackage; })
    # Can't set `hyprland.config.plugin` because the key is expected to be unique,
    # and that attribute should be used for plugin config, not loading them.
    (lib.mkIf (cfg.plugins != [ ]) {
      wayland.windowManager.hyprland.configFile."hyprland.conf".text =
        lib.mkOrder 350 (toConfigString {
          plugin =
            map (package: "${package}/lib/lib${package.pname}.so") cfg.plugins;
        });
    })
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
          XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
          if [[ -d "$XDG_RUNTIME_DIR/hypr" ]]; then
            for instance in $(${cfg.finalPackage}/bin/hyprctl instances -j | jq ".[].instance" -r); do
              response="$(${cfg.finalPackage}/bin/hyprctl -i "$instance" reload config-only 2>&1)"
              [[ $response =~ ^ok ]] && \
                echo "Hyprland instance reloaded: $HYPRLAND_INSTANCE_SIGNATURE"
            done
          fi
        )
      '';
    })
  ]);
}
