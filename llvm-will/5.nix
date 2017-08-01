{ callPackage, fetchurl }:

callPackage ./generic.nix {
  sources = import ./sources/release_50 { inherit fetchurl; };
  release_version = "5.0.0";
}
