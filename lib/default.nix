lib: lib0:
lib0 // {
  hyprnix = lib0.hyprnix or { } // {
    types = lib0.hyprnix.types or { } // import ./hyprnix/types.nix lib lib0;
  };
}
