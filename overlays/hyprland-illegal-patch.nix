# Resurrect: <https://github.com/hyprwm/Hyprland/commit/c1bcbdb3dd1370351738d3874a58c57be8faaa9a#diff-e13c472bc344de78a1c62ff7e7863db5aa39ffdef86c352791999eac6056b26cL35>
pkgs: pkgs0: {
  hyprland-illegal-patch = pkgs0.hyprland.override {
    wlroots = pkgs.wlroots-hyprland-illegal-patch;
    xwayland = pkgs.xwayland-hyprland-illegal-patch;
  };

  # <https://aur.archlinux.org/packages/wlroots-hidpi-xprop-git>
  wlroots-hyprland-illegal-patch = pkgs0.wlroots-hyprland.overrideAttrs
    (self: super: {
      patches = (super.patches or [ ]) ++ [
        (pkgs.fetchpatch {
          url =
            "https://raw.githubusercontent.com/hyprwm/Hyprland/c1bcbdb3dd1370351738d3874a58c57be8faaa9a/nix/patches/wlroots-hidpi.patch";
          hash = "sha256-l37CXEpVO7ZK+z48ykiF1D//XN6rLzmRyBr8sM50ZYA=";
        })
        (pkgs.fetchpatch {
          url =
            "https://gitlab.freedesktop.org/wlroots/wlroots/-/commit/18595000f3a21502fd60bf213122859cc348f9af.diff";
          hash = "sha256-jvfkAMh3gzkfuoRhB4E9T5X1Hu62wgUjj4tZkJm0mrI=";
          revert = true;
        })
      ];
    });

  # <https://aur.archlinux.org/packages/xorg-xwayland-hidpi-xprop>
  xwayland-hyprland-illegal-patch = pkgs0.xwayland.overrideAttrs (self: super: {
    patches = (super.patches or [ ]) ++ [
      (pkgs.fetchpatch {
        url =
          "https://raw.githubusercontent.com/hyprwm/Hyprland/c1bcbdb3dd1370351738d3874a58c57be8faaa9a/nix/patches/xwayland-vsync.patch";
        hash = "sha256-VjquNMHr+7oMvnFQJ0G0whk1/253lZK5oeyLPamitOw=";
      })
      # Updated for chunk #1 rejection
      # <https://raw.githubusercontent.com/hyprwm/Hyprland/c1bcbdb3dd1370351738d3874a58c57be8faaa9a/nix/patches/xwayland-hidpi.patch>
      ./xwayland-hidpi.patch
    ];
  });
}

### ATTEMPTED MORE RECENT PATCHES FROM THE AUR ###

### FOR WLROOTS
# (pkgs.fetchpatch {
#   url =
#     "https://aur.archlinux.org/cgit/aur.git/plain/0001-xwayland-support-HiDPI-scale.patch?h=wlroots-hidpi-xprop-git";
#   hash = "sha256-ceDAlQARl6d2cuSHvWIvSRRjFTZ4qBlGGpsrE/0vxqg=";
# })
# (pkgs.fetchpatch {
#   url =
#     "https://aur.archlinux.org/cgit/aur.git/plain/0002-Fix-configure_notify-event.patch?h=wlroots-hidpi-xprop-git";
#   hash = "sha256-IPNWY9Dm4jsq8WzkzDONLuQvUOM9Mpsyd3gR+Krjkss=";
# })
# (pkgs.fetchpatch {
#   url =
#     "https://aur.archlinux.org/cgit/aur.git/plain/0003-Fix-size-hints-under-Xwayland-scaling.patch?h=wlroots-hidpi-xprop-git";
#   hash = "sha256-vCI01bHGFONzYVTJIXBJenHgC5Q65GYotjuWhoIY0lk=";
# })

### FOR XWAYLAND
# (pkgs.fetchpatch {
#   url =
#     "https://aur.archlinux.org/cgit/aur.git/plain/hidpi.patch?h=xorg-xwayland-hidpi-xprop";
#   hash = "sha256-+OP3B8APzVXih6xAz4OcIbfdwB/QQi7f6IW8GV1p/Kk=";
# })
# (pkgs.fetchpatch {
#   url =
#     "https://aur.archlinux.org/cgit/aur.git/plain/hidpi.patch?h=xorg-xwayland-hidpi-xprop";
#   hash = "sha256-+OP3B8APzVXih6xAz4OcIbfdwB/QQi7f6IW8GV1p/Kk=";
# })
