{ lib, pkgs, ... }:
formatOptions:
let
  inherit (lib.hyprnix.hyprlang) mkSectionNode mkVariableNode attrsToNodeList;

  toConfigString = lib.generators.toHyprlang
    (formatOptions // { astBuilder = deviceAttrsToNodeList [ ]; });

  deviceAttrsToNodeList = path: attrs:
    lib.mapAttrsToList (deviceName: deviceConfig:
      let
        nameNode = mkVariableNode [ "device" ] "name" deviceName;
        configNodes = attrsToNodeList [ "device" ] deviceConfig;
        sectionNodes = [ nameNode ] ++ configNodes;
      in mkSectionNode path "device" sectionNodes) attrs;
in {
  # freeformType = types.attrsOf types.anything;
  # type = with lib.types;
  #   let
  #     valueType = oneOf [ bool number singleLineStr listOfValueTypes ];
  #     listOfValueTypes = listOf valueType;
  #   in attrsOf valueType;
  type = with lib.types; attrsOf anything;

  lib = lib.hyprnix.hyprlang;

  inherit toConfigString;
  generate = name: value: pkgs.writeText name (toConfigString value);
}
