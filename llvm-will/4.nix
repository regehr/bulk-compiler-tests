{ callPackage, fetchurl }:

let
  release_version = "4.0.1";

  fetchsrc = name: sha256: {
    inherit name;
    src = fetchurl {
      url = "http://llvm.org/releases/${release_version}/${name}-${release_version}.src.tar.xz";
      inherit sha256;
    };
  };
  sources = {
    llvm = fetchsrc "llvm" "0l9bf7kdwhlj0kq1hawpyxhna1062z3h7qcz2y8nfl9dz2qksy6s";
    clang = fetchsrc "cfe" "16vnv3msnvx33dydd17k2cq0icndi1a06bg5vcxkrhjjb1rqlwv1";

    lld = fetchsrc "lld" "1v9nkpr158j4yd4zmi6rpnfxkp78r1fapr8wji9s6v176gji1kk3";
    libcxx = fetchsrc "libcxx" "0k6cmjcxnp2pyl8xwy1wkyyckkmdrjddim94yf1gzjbjy9qi22jj";
    libcxxabi = fetchsrc "libcxxabi" "0cqvzallxh0nwiijsf6i4d5ds9m5ijfzywg7376ncv50i64if24g";
    libunwind = fetchsrc "libunwind" "0m95m7b0iz57f9vj5aricmh4s7vdi20f16162yszkd34nwrjw1rv";

    compiler-rt = fetchsrc "compiler-rt" "0h5lpv1z554szi4r4blbskhwrkd78ir50v3ng8xvk1s86fa7gj53";
    clang-tools-extra = fetchsrc "clang-tools-extra" "1dhmp7ccfpr42bmvk3kp37ngjpf3a9m5d4kkpsn7d00hzi7fdl9m";
  };

in
  callPackage ./generic.nix { inherit sources release_version; }
