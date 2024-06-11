{ lib, pkgs, ... }:
formatOptions:
let
  inherit (lib.hyprnix.hyprlang) isRepeatNode mkVariableNode mkRepeatNode;

  toConfigString = lib.generators.toHyprlang (formatOptions // {
    astBuilder = keyBindsToNodeList [ ];
    indentChars = "";
    lineBreakPred = prev: next:
      let
        isSubmap = node: isRepeatNode prev && node.name == "submap";
        betweenSubmaps = isSubmap prev && isSubmap next;
        betweenRepeats = isRepeatNode prev && isRepeatNode next;
      in prev != null && (betweenRepeats || betweenSubmaps);
  });

  keyBindsToNodeList = path: attrs:
    let
      default = lib.pipe attrs [
        (attrs:
          if attrs ? submap then removeAttrs attrs [ "submap" ] else attrs)
        (bindAttrsToNodeList [ ])
      ];
      submaps = lib.pipe attrs [
        (attrs: if attrs ? submap then attrs.submap else { })
        (lib.mapAttrs (name: bindAttrsToNodeList [ "submap" ]))
        (lib.mapAttrsToList (name: nodes:
          let
            nameNode = mkVariableNode [ "submap" name ] "submap" name;
            resetNode = mkVariableNode [ "submap" name ] "submap" "reset";
            nodes' = [ nameNode ] ++ nodes ++ [ resetNode ];
          in mkRepeatNode [ "submap" ] "submap" nodes'))
      ];
    in lib.concatLists [ default submaps ];

  bindAttrsToNodeList = path:
    (lib.mapAttrsToList (bindKw: chordAttrs:
      mkRepeatNode path bindKw (chordAttrsToNodeList path bindKw chordAttrs)));

  chordAttrsToNodeList = path: bindKw: attrs:
    lib.concatLists (lib.mapAttrsToList (chord: value:
      if lib.isList value then
        (map (dispatcher: mkVariableNode path bindKw "${chord}, ${dispatcher}")
          value)
      else
        [ (mkVariableNode path bindKw "${chord}, ${value}") ]) attrs);
in {
  # freeformType = types.attrsOf types.anything;
  # type = with lib.types;
  #   let
  #     valueType =
  #       oneOf [ bool number singleLineStr attrsOfValueTypes listOfValueTypes ];
  #     attrsOfValueTypes = attrsOf valueType;
  #     listOfValueTypes = listOf valueType;
  #   in attrsOfValueTypes;
  # TODO
  type = with lib.types; attrsOf anything;

  lib = lib.hyprnix.hyprlang;

  inherit toConfigString;
  generate = name: value: pkgs.writeText name (toConfigString value);
}
