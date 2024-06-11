lib: _:
let
  inherit (lib) types;

  configFile = pkgs: basePath:
    types.submodule ({ config, name, ... }: {
      options = {
        target = lib.mkOption {
          type = types.singleLineStr;
          readOnly = true;
          description = lib.mdDoc ''
            The path of which to write {option}`source` or {option}`text`.

            This is always specified as the attribute name of this
            object in its parent attribute set.
          '';
        };
        source = lib.mkOption {
          type = types.path;
          default = null;
          description = lib.mdDoc ''
            If {option}`text` is not specified, this path will be used.

            If this is a directory, contents will be linked recursively.
          '';
        };
        text = lib.mkOption {
          type = types.nullOr types.lines;
          default = null;
          description = lib.mdDoc ''
            The text contents of the file.

            This option can be set mutiple times,
            and new text will be appended after previous lines.
            Use `lib.mkOrder` to ensure lines are written
            in the order you desire.

            This option takes precedence over {option}`source`.
          '';
        };
        executable = lib.mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc ''
            If this file should be marked as executable.

            Useful for scripts used by the Hyprland config itself,
            for example keybinds using the `exec` dispatcher.

            Only works if {option}`text` is set.
          '';
        };
      };
      config = {
        target = name;
        source = lib.mkIf (config.text != null) (pkgs.writeTextFile {
          name = "${basePath}/${config.target}";
          destination = "/${config.target}";
          inherit (config) text executable;
        });
      };
    });
in { # #
  inherit configFile;
}
