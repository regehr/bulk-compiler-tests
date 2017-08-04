let
  pkgs = import <nixpkgs> {}; # not using "with" to make it clearer what-comes-from-where
  llvmHEADPackages = pkgs.callPackage ./llvm-will { };
  clangStdenv = llvmHEADPackages.stdenv;
in {
  XXX = (pkgs.XXX.override {
    stdenv = clangStdenv;
  }).overrideAttrs(oldAttrs: {
    doCheck = true;
    enableParallelBuilding = true;
  });
}
