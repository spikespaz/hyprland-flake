lib: lib0:
lib0 // {
  hyprnix = lib0.hyprnix or { } // {
    types = lib0.hyprnix.types or { } // import ./hyprnix/types.nix lib lib0;
    hyprlang = lib0.hyprnix.hyprlang or { }
      // import ./hyprnix/hyprlang.nix lib lib0;
  };
  generators = lib0.generators or { } // {
    toHyprlang = lib.hyprnix.hyprlang.toConfigString;
  };
}
