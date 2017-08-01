{ lib, stdenv, fetch_v, cmake, libcxxabi, fixDarwinDylibNames, version, libcxx_version, libcxxabi_version, useMusl ? false, libcxxStatic ? false, useLibCXXABI ? false}:

stdenv.mkDerivation rec {
  # version = "${version}-${builtins.substring 0 7 libcxx_version}";
  # name = "libc++-${version}";
  name = "libc++-${version}-${builtins.substring 0 7 libcxx_version}";


  postUnpack = ''
    unpackFile ${libcxxabi.src}
  '';

  preConfigure = ''
    # Get headers from the cxxabi source so we can see private headers not installed by the cxxabi package
  '' + lib.optionalString (useLibCXXABI) ''
    cmakeFlagsArray=($cmakeFlagsArray -DLIBCXX_CXX_ABI_INCLUDE_PATHS="${libcxxabi}/include")
  '' + lib.optionalString (!useLibCXXABI) ''
    cmakeFlagsArray=($cmakeFlagsArray -DLIBCXX_CXX_ABI_INCLUDE_PATHS="../../libcxxabi-${libcxxabi_version}/include")
  '' + lib.optionalString (useMusl) ''
    # TODO: Don't require setting this, especially since it becomes redundant!
    export NIX_CXXSTDLIB_COMPILE+=" -D_LIBCPP_HAS_MUSL_LIBC=1"
  '';

  patches = lib.optional stdenv.isDarwin ./darwin.patch
            ++ lib.optionals (useMusl) [ ./libcxx-0001-musl-hacks.patch ./libcxx-0002-pthread_mutex_init-musl.patch ];

  buildInputs = [ cmake libcxxabi ] ++ lib.optional stdenv.isDarwin fixDarwinDylibNames;

  cmakeFlags =
    [ "-DCMAKE_BUILD_TYPE=Release"
    #"-DLIBCXX_LIBCXXABI_LIB_PATH=${libcxxabi}/lib"
      "-DLIBCXX_CXX_ABI_LIBRARY_PATH=${libcxxabi}/lib"
      # "-DLIBCXX_LIBCPPABI_VERSION=2"
      "-DLIBCXX_ABI_VERSION=1"
      "-DLIBCXX_CXX_ABI=libcxxabi"
    ] ++ lib.optionals (libcxxStatic) [
      "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=1"
      "-DLIBCXX_ENABLE_SHARED=0"
    ] ++ lib.optionals (useMusl) [
      "-DLIBCXX_HAS_MUSL_LIBC=1"
    ];

  enableParallelBuilding = true;

  linkCxxAbi = stdenv.isLinux;

  setupHook = ./setup-hook.sh;

  meta = {
    homepage = http://libcxx.llvm.org/;
    description = "A new implementation of the C++ standard library, targeting C++11";
    license = "BSD";
    platforms = stdenv.lib.platforms.unix;
    broken = true;
  };
}
