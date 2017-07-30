let
  pkgs = import <nixpkgs> {}; # not using "with" to make it clearer what-comes-from-where
  llvmHEADPackages = pkgs.callPackage ./llvm { };
  clangStdenv = llvmHEADPackages.stdenv;
in {
  bash = (pkgs.bash.override {
    stdenv = clangStdenv;
  }).overrideAttrs(oldAttrs: {
    doCheck = true;
    enableParallelBuilding = true;
  });
}
