{ fetchurl }:

let
  fetch_v = ver: name: sha256: fetchurl {
    url = "https://github.com/llvm-mirror/${name}/archive/${ver}.tar.gz";
    name = "${name}-${builtins.substring 0 7 ver}.tar.gz";
    inherit sha256;
  };
  fetch_src = { rev, name, sha256, svn_rev }: {
    inherit rev name sha256 svn_rev;
    src = fetch_v rev name sha256;
    rev_short = "${builtins.substring 0 7 rev}";
  };
in {
  llvm = fetch_src (import ./llvm.nix);
  clang = fetch_src (import ./clang.nix);
  clang-tools-extra = fetch_src (import ./clang-tools-extra.nix);
  compiler-rt = fetch_src (import ./compiler-rt.nix);
  lld = fetch_src (import ./lld.nix);
  libcxx = fetch_src (import ./libcxx.nix);
  libcxxabi = fetch_src (import ./libcxxabi.nix);
  libunwind = fetch_src (import ./libunwind.nix);
}

