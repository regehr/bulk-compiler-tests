{ newScope, stdenv, fetchurl, overrideCC, wrapCC, overrideTriple ? null
, sources
, release_version
, llvmPatches ? []
}:
let

  foo = false;

  callPackage = newScope (self // {
    inherit stdenv release_version sources;
    inherit overrideTriple;
    mkVerSuffix = src: "${release_version}" +
      (if src ? svn_rev then "-${src.svn_rev}" else "");
  });

  older_than_5 = stdenv.lib.versionOlder release_version "5";
  older_than_6 = stdenv.lib.versionOlder release_version "6";

  muslPatches = [
    ./patches/llvm-0002-Fix-build-with-musl-libc.patch
    (
      if older_than_5 then
        ./patches/llvm-0004-Disable-use-of-dlopen-don-t-require-it-in-MCJIT.patch
     else
       ./patches/llvm5-0004-Disable-use-of-dlopen-don-t-require-it-in-MCJIT.patch
    )
  ] ++ stdenv.lib.optional older_than_5
    ./patches/llvm-0003-Fix-DynamicLibrary-to-build-with-musl-libc.patch;

  outlinerPatches = stdenv.lib.optional (!older_than_5) ./patches/llvm5-outliner.patch;

  wllvmPatches = [
    (
      if older_than_6 then
        ./patches/llvm-no-proc-self-exe.patch
      else
        ./patches/llvm6-no-proc-self-exe.patch
    )
  ];

  llvm_patches = llvmPatches
    ++ stdenv.lib.optionals false muslPatches
    ++ outlinerPatches
    # XXX: Breaks allvm-tools test re:argv0: https://gravity.cs.illinois.edu/build/1034231/nixlog/1
    # ++ stdenv.lib.optionals false wllvmPatches
    ;

  self = {
    llvm = callPackage ./llvm.nix { inherit llvm_patches; };

    # lld = callPackage ./lld.nix { inherit llvm_patches; };

    # lld-standlone = callPackage ./lld-standalone.nix {};

    clang-unwrapped = callPackage ./clang {};

    clang = wrapCC self.clang-unwrapped;

    stdenv = overrideCC stdenv self.clang;

    all = callPackage ./all.nix { inherit llvm_patches; };

    toolchain = callPackage ./all.nix {
      inherit llvm_patches;
      static = true;
      toolchainOnly = true;
      withLLD = false;
    };

    ## libcxx = callPackage ./libc++ {};

    ## libcxxabi = callPackage ./libc++abi.nix {};

    lit = callPackage ./lit.nix {};

    ## opt-viewer = callPackage ./opt-viewer.nix { };

  };
in self
