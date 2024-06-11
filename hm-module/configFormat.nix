# This file copies the style of:
# <https://github.com/NixOS/nixpkgs/blob/55bf31e28e1b11574b56926d8c80f45271d696d5/pkgs/pkgs-lib/formats.nix>
{ lib, pkgs, ... }:
formatOptions@{
# Required ordering of attribute paths, required from `config`.
configOrder,
# A default `sortPred` is provided based on the `configOrder` list.
sortPred ? pathA: pathB:
  let
    # An implimentation of order for an attribute path.
    #
    # The `orderKeys` is a list of patterns to match against
    # attribute paths.
    #
    # Each attribute `path` is a list of strings,
    # and each member of `orderKeys` is also a list of strings,
    # but each is a regular expression.
    #
    # We compute the "order" of the `path` by finding the index of
    # the last matching pattern.
    #
    # If the `path` failed to match any pattern in `orderKeys`,
    # it will be ordered as `-1`.
    #
    # ---
    #
    # I know that this is confusing, but it's necessary for certain
    # keywords. Take, for example, `animations:animation` and
    # `animations:bezier`: the bezier curve must be defined before it
    # can be used by an instance of the `animation` keyword.
    #
    # In most cases, this simple (albiet convoluted) algorithm
    # should do exactly what we want:
    # allow the user to define a custom order,
    # but provide sane defaults that work for past, present,
    # and future versions of the Hyprland config.
    orderPath = path: orderKeys:
      lib.lastIndexOfDefault (-1) true (map (pathPatterns:
        builtins.all ({ fst, snd }: builtins.match fst snd != null)
        (lib.zipLists pathPatterns path)) orderKeys);
    ia = orderPath pathA configOrder;
    ib = orderPath pathB configOrder;
  in ia < ib,
#
... }:
let
  toConfigString = lib.generators.toHyprlang
    (removeAttrs formatOptions [ "configOrder" ] // { inherit sortPred; });
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
