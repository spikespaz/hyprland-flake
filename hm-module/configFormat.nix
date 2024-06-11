# This file copies the style of:
# <https://github.com/NixOS/nixpkgs/blob/55bf31e28e1b11574b56926d8c80f45271d696d5/pkgs/pkgs-lib/formats.nix>
{ lib, pkgs, ... }:
formatOptions:
let toConfigString = lib.generators.toHyprlang formatOptions;
in {
  # freeformType = types.attrsOf types.anything;
  type = with lib.types;
    let
      valueType =
        oneOf [ bool number singleLineStr attrsOfValueTypes listOfValueTypes ];
      attrsOfValueTypes = attrsOf valueType;
      listOfValueTypes = listOf valueType;
    in attrsOfValueTypes;

  lib = lib.hyprnix.hyprlang;

  inherit toConfigString;
  generate = name: value: pkgs.writeText name (toConfigString value);
}
