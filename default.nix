with import <nixpkgs> {};

{
  #hello = hello.override {
  #  stdenv = clangStdenv;
  #};
  hello.Attrs = hello.overrideAttrs {
    doCheck = true;
    separateDebugInfo = true;
  };
}
