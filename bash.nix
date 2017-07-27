with import <nixpkgs> {};

{
  bash = (bash.override {
    stdenv = clangStdenv;
  }).overrideAttrs(oldAttrs: {
    doCheck = true;
    enableParallelBuilding = true;
  });
}
