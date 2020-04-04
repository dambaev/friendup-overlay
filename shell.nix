{ nixpkgs ? import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; }}:
nixpkgs.callPackage ./friendup.nix { }