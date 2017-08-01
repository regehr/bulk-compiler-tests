{ stdenv
# Clang deps
, cmake, libedit, libxml2, llvm, python
# Configuration, sources
, sources, mkVerSuffix, release_version
, overrideTriple ? null
}:

assert !stdenv.isMusl; # This isn't patched for use w/musl, see all.nix

let
  gcc = if stdenv.cc.isGNU then stdenv.cc.cc else stdenv.cc.cc.gcc;
  older_than_5 = stdenv.lib.versionOlder release_version "5";
  purity_patch = if older_than_5 then ./purity.patch else ./purity-5.0.patch;
  self = stdenv.mkDerivation {
    src = sources.clang.src;
    version = mkVerSuffix sources.clang;
    name = "clang-${self.version}";

    unpackPhase = ''
      unpackFile ${sources.clang.src}
      chmod -R u+w ${sources.clang.name}-*
      mv ${sources.clang.name}-* clang
      sourceRoot=$PWD/clang
      unpackFile ${sources.clang-tools-extra.src}
      chmod -R u+w clang-tools-extra-*
      mv clang-tools-extra-* $sourceRoot/tools/extra
    '';

    buildInputs = [ cmake libedit libxml2 llvm python ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DCMAKE_CXX_FLAGS=-std=c++11"
      "-DLLVM_TOOLS_INSTALL_DIR=bin"
    ] ++
    # Maybe with compiler-rt this won't be needed?
    (stdenv.lib.optional (stdenv.isLinux && !stdenv.isWLLVM) "-DGCC_INSTALL_PREFIX=${gcc}") ++
    (stdenv.lib.optional (stdenv.cc.libc != null) "-DC_INCLUDE_DIRS=${stdenv.cc.libc}/include")
    ++ stdenv.lib.optionals (overrideTriple != null) [
      "-DLLVM_HOST_TRIPLE=${overrideTriple}"
      "-DLLVM_DEFAULT_TARGET_TRIPLE=${overrideTriple}"
      "-DTARGET_TRIPLE=${overrideTriple}"
    ];

    patches = [ purity_patch ];

    postPatch = if older_than_5 then ''
      sed -i -e 's/Args.hasArg(options::OPT_nostdlibinc)/true/' lib/Driver/Tools.cpp
      sed -i -e 's/DriverArgs.hasArg(options::OPT_nostdlibinc)/true/' lib/Driver/ToolChains.cpp
    '' else ''
      sed -i -e 's/DriverArgs.hasArg(options::OPT_nostdlibinc)/true/' \
             -e 's/Args.hasArg(options::OPT_nostdlibinc)/true/' \
             lib/Driver/ToolChains/*.cpp
    '';

    # Clang expects to find LLVMgold in its own prefix
    # Clang expects to find sanitizer libraries in its own prefix
    postInstall = ''
      ln -sv ${llvm}/lib/LLVMgold.so $out/lib
      ln -sv ${llvm}/lib/clang/${release_version}/lib $out/lib/clang/${release_version}/
      ln -sv $out/bin/clang $out/bin/cpp
    '';

    enableParallelBuilding = true;

    passthru = {
      lib = self; # compatibility with gcc, so that `stdenv.cc.cc.lib` works on both
      isClang = true;
      inherit release_version;
      src = sources.clang.src;
    } // stdenv.lib.optionalAttrs stdenv.isLinux {
      inherit gcc;
    };

    meta = {
      description = "A c, c++, objective-c, and objective-c++ frontend for the llvm compiler";
      homepage    = http://llvm.org/;
      license     = stdenv.lib.licenses.bsd3;
      platforms   = stdenv.lib.platforms.all;
    };
  };
in self
