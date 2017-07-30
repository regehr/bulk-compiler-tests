# { lowPrio, newScope, stdenv, cmake, libxml2, python2, isl, fetchurl, overrideCC, wrapCC, darwin, ccWrapperFun }:

{ pkgs ? (import <nixpkgs> {}) }:

with pkgs;
let
  callPackage = newScope (self // { inherit stdenv cmake libxml2 python2 isl release_version version fetch fetchsvn; });

  release_version = "HEAD";
  version = release_version; # differentiating these is important for rc's

  fetch = loc: fetchsvn {
    url = "http://llvm.org/svn/llvm-project/${loc}/trunk";
    rev = "HEAD";
  };

  compiler-rt_src = fetch "compiler-rt";
  clang-tools-extra_src = fetch "clang-tools-extra";

  # Add man output without introducing extra dependencies.
  overrideManOutput = drv:
    let drv-manpages = drv.override { enableManpages = true; }; in
    drv // { man = drv-manpages.man; /*outputs = drv.outputs ++ ["man"];*/ };

  llvm = callPackage ./llvm.nix {
    inherit compiler-rt_src stdenv;
  };

  clang-unwrapped = callPackage ./clang {
    inherit clang-tools-extra_src stdenv;
  };

  self = {
    llvm = overrideManOutput llvm;
    clang-unwrapped = overrideManOutput clang-unwrapped;

    llvm-manpages = lowPrio self.llvm.man;
    clang-manpages = lowPrio self.clang-unwrapped.man;

    clang = wrapCC self.clang-unwrapped;

    openmp = callPackage ./openmp.nix {};

    libcxxClang = ccWrapperFun {
      cc = self.clang-unwrapped;
      isClang = true;
      inherit (self) stdenv;
      /* FIXME is this right? */
      inherit (stdenv.cc) libc nativeTools nativeLibc;
      extraPackages = [ self.libcxx self.libcxxabi ];
    };

    stdenv = overrideCC stdenv self.clang;

    libcxxStdenv = overrideCC stdenv self.libcxxClang;

    lld = callPackage ./lld.nix {};

    # lldb = callPackage ./lldb.nix {};

    libcxx = callPackage ./libc++ {};

    libcxxabi = callPackage ./libc++abi.nix {};
  };
in self
