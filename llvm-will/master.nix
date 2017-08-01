# { callPackage, fetchurl }:

{ pkgs ? (import <nixpkgs> {}) }:

with pkgs;

callPackage ./generic.nix {
  sources = import ./sources/master { inherit fetchurl; };
  release_version = "6.0.0";
}
