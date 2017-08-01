{ stdenv
#, perl
#, groff
, cmake
, python
#, libffi
, binutils
, libxml2
#, valgrind
#, ncurses
#, zlib
, sources
, llvm_patches
, mkVerSuffix
, debugVersion ? false
, overrideTriple ? null
, release_version
, static ? false
, staticRTLibs ? false
, withLLD ? true
, toolchainOnly ? false
, withClangToolsExtra ? !toolchainOnly
, enableAssertions? !toolchainOnly
, removeRuntimePythonDep? true
, removeRuntimeLibXML2Dep? true
, enableWasm ? false
}:

assert stdenv.isWLLVM -> (static -> toolchainOnly);
assert toolchainOnly -> static;

let
  src = sources.llvm.src;
  gcc = if stdenv.cc.isGNU then stdenv.cc.cc else stdenv.cc.cc.gcc;
  RT_SHARED = if staticRTLibs then "OFF" else "ON";
  RT_STATIC = if staticRTLibs then "ON" else "OFF";
  older_than_5 = stdenv.lib.versionOlder release_version "5";
  purity_patch = if older_than_5 then ./clang/purity.patch else ./clang/purity-5.0.patch;
in
  # assert (stdenv.isMusl -> older_than_5); # Catch attempts to use 5.0/master with musl
  stdenv.mkDerivation rec {
  name = "llvm-all-${mkVerSuffix sources.llvm}";

  unpackPhase = ''
    unpackFile ${src}
    chmod -R u+w llvm-*
    mv llvm-* llvm
    sourceRoot=$PWD/llvm
  '' + stdenv.lib.optionalString withLLD ''
    unpackFile ${sources.lld.src}
    chmod -R u+w lld-*
    mv lld-* $sourceRoot/tools/lld
  '' + ''
    unpackFile ${sources.clang.src}
    chmod -R u+w ${sources.clang.name}-*
    mv ${sources.clang.name}-* $sourceRoot/tools/clang
    patch -p1 -i ${purity_patch} -d $sourceRoot/tools/clang
  '' + stdenv.lib.optionalString withClangToolsExtra ''
    unpackFile ${sources.clang-tools-extra.src}
    chmod -R u+w clang-tools-extra-*
    mv clang-tools-extra-* $sourceRoot/tools/clang/tools/extra
  '' + ''
    unpackFile ${sources.compiler-rt.src}
    chmod -R u+w compiler-rt-*
    mv compiler-rt-* $sourceRoot/projects/compiler-rt
    unpackFile ${sources.libunwind.src}
    chmod -R u+w libunwind-*
    mv libunwind-* $sourceRoot/projects/libunwind
  '' + stdenv.lib.optionalString older_than_5 ''
    patch -p1 -i ${patches/libunwind-stack_non_exec_linux.patch} -d $sourceRoot/projects/libunwind
  '' + ''
    unpackFile ${sources.libcxx.src}
    chmod -R u+w libcxx-*
    mv libcxx-* $sourceRoot/projects/libcxx
    unpackFile ${sources.libcxxabi.src}
    chmod -R u+w libcxxabi-*
    mv libcxxabi-* $sourceRoot/projects/libcxxabi
    patch -p1 -i ${./libc++/libcxx-0001-musl-hacks.patch} -d $sourceRoot/projects/libcxx/

  '' + (if older_than_5 then ''
    sed -i -e 's/Args.hasArg(options::OPT_nostdlibinc)/true/' $sourceRoot/tools/clang/lib/Driver/Tools.cpp
    sed -i -e 's/DriverArgs.hasArg(options::OPT_nostdlibinc)/true/' $sourceRoot/tools/clang/lib/Driver/ToolChains.cpp

    sed -i -e 's@"-lgcc[^"]*"@"-lunwind"@g' $sourceRoot/tools/clang/lib/Driver/Tools.cpp
  '' else ''
    sed -i -e 's/DriverArgs.hasArg(options::OPT_nostdlibinc)/true/' \
           -e 's/Args.hasArg(options::OPT_nostdlibinc)/true/' \
           -e 's@"-lgcc[^"]*"@"-lunwind"@g' \
           $sourceRoot/tools/clang/lib/Driver/ToolChains/*.cpp

    # Disable 'availability' bits on non-darwin:
    substituteInPlace $sourceRoot/projects/libcxx/include/__config \
      --replace '__has_feature(attribute_availability_with_strict)' 'false' \
      --replace '__has_feature(attribute_availability_in_templates)' 'false'
  '') + ''

    sed -i -e 's@__GNUC__@__GLIBC__@g' $sourceRoot/lib/ExecutionEngine/RuntimeDyld/RTDyldMemoryManager.cpp

    '' + stdenv.lib.optionalString (stdenv.isMusl) ''
    export NIX_CFLAGS_COMPILE+=" -D_LIBCPP_HAS_MUSL_LIBC=1"

    sed -i 's@/lib64/ld-linux-x86-64.so.2@/lib/ld-musl-x86_64.so.1@' $sourceRoot/tools/clang/lib/Driver/${if older_than_5 then "Tools.cpp" else "ToolChains/Linux.cpp"}
    sed -i -e 's/linux-gnu/linux-musl/g' -e 's@LIBC=gnu@LIBC=musl@' `find $sourceRoot -name "confi*.guess" -o -name "confi*.sub"`
    sed -i 's@linux-gnu@linux-musl@g' `grep -lr linux-gnu $sourceRoot`
    sed -i 's@^#if defined(HAVE_POSIX_FALLOCATE)@#if 0@' $sourceRoot/lib/Support/Unix/Path.inc
    '';

  buildInputs = [ cmake python libxml2 ];

  # propagatedBuildInputs = [ ncurses zlib ];

  # hacky fix: New LLVM releases require a newer OS X SDK than
  # 10.9. This is a temporary measure until nixpkgs darwin support is
  # updated.
  # patchPhase = stdenv.lib.optionalString stdenv.isDarwin ''
#        sed -i 's/os_trace(\(.*\)");$/printf(\1\\n");/g' ./projects/compiler-rt/lib/sanitizer_common/sanitizer_mac.cc

  patches = llvm_patches;

  hardeningDisable = "all";

  #  "-DLLVM_ENABLE_FFI=ON"
  #  "-DLLVM_ENABLE_RTTI=ON"

  cmakeFlags = with stdenv; [
    "-DCMAKE_BUILD_TYPE=${if debugVersion then "Debug" else "Release"}"
    "-DLLVM_INSTALL_UTILS=ON"  # Needed by rustc
    "-DLLVM_BUILD_TESTS=OFF"
    ("-DLLVM_ENABLE_ASSERTIONS=" + (if enableAssertions then "ON" else "OFF"))
    "-DLLVM_ENABLE_BACKTRACES=OFF"
    "-DLLVM_ENABLE_TERMINFO=OFF" # Otherwise dies trying to find terminfo resources when relocated into bootstrap, maybe.
    "-DLLVM_ENABLE_RTTI=ON"
    # "-DLLVM_ENABLE_EH=OFF"
    # "-DLLVM_ENABLE_FFI=OFF"
    #"-DLLVM_ENABLE_TERMINFO=OFF"
    #"-DLLVM_ENABLE_THREADS=OFF"
    "-DLLVM_ENABLE_ZLIB=OFF"
    "-DLLVM_TARGETS_TO_BUILD=host"
    "-DCOMPILER_RT_CAN_EXECUTE_TESTS=OFF" # Needed to build compiler-rt...?

    # Disable bunch of clang features we don't use
    "-DCLANG_ENABLE_ARCMT=OFF"
    "-DCLANG_INSTALL_SCANVIEW=OFF"
    "-DCLANG_INSTALL_SCANBUILD=OFF"
    "-DCLANG_PLUGIN_SUPPORT=OFF"

    "-DLIBCXXABI_USE_LLVM_UNWINDER=ON"
    "-DLIBCXX_HAS_GCC_S_LIB=OFF"

    # TODO: Why do we set this, is it really needed?
    "-DC_INCLUDE_DIRS=${stdenv.cc.libc}/include"

    "-DCLANG_DEFAULT_RTLIB=compiler-rt"
    "-DCLANG_DEFAULT_CXX_STDLIB=libc++"

    # (This is the LLVM default)
    "-DLLVM_LINK_LLVM_DYLIB=OFF"

    #    "-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
    "-DLIBUNWIND_ENABLE_SHARED=${RT_SHARED}"
    "-DLIBUNWIND_ENABLE_STATIC=${RT_STATIC}"
  ] ++ stdenv.lib.optional (!isDarwin)
    "-DLLVM_BINUTILS_INCDIR=${binutils.dev}/include"
    ++ stdenv.lib.optionals ( isDarwin) [
    "-DLLVM_ENABLE_LIBCXX=ON"
    "-DCAN_TARGET_i386=false"
  ] ++ stdenv.lib.optionals (overrideTriple != null) [
    "-DLLVM_HOST_TRIPLE=${overrideTriple}"
    "-DLLVM_DEFAULT_TARGET_TRIPLE=${overrideTriple}"
    "-DTARGET_TRIPLE=${overrideTriple}"
  ] ++ stdenv.lib.optionals (stdenv.isMusl) [
    "-DCOMPILER_RT_BUILD_SANITIZERS=OFF"
    "-DCOMPILER_RT_BUILD_XRAY=OFF"
    "-DLIBCXX_HAS_MUSL_LIBC=ON"
  ] ++ stdenv.lib.optionals (stdenv.cc.isClang) [
    "-DLIBCXXABI_USE_COMPILER_RT=ON"
    # TODO: Having clang doesn't mean we have libcxx/libcxxabi!
    #"-DLLVM_ENABLE_LIBCXX=ON"
    #"-DLLVM_ENABLE_LIBCXXABI=ON"
    "-DGCC_INSTALL_PREFIX=GCC-NOTFOUND"
  ] ++ stdenv.lib.optionals (stdenv.cc.isGNU) [
    "-DGCC_INSTALL_PREFIX=${gcc}"
  ] ++ stdenv.lib.optionals (staticRTLibs) [
    "-DLIBCXXABI_ENABLE_SHARED=${RT_SHARED}"
    "-DLIBCXXABI_ENABLE_STATIC=${RT_STATIC}"

    "-DLIBCXX_ENABLE_SHARED=${RT_SHARED}"
    "-DLIBCXX_ENABLE_STATIC=${RT_STATIC}"
    "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=${RT_STATIC}"
    "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=${RT_STATIC}"
  ] ++ stdenv.lib.optionals (toolchainOnly) [
    "-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
    "-DCLANG_ENABLE_STATIC_ANALYZER=OFF"
  ] ++ stdenv.lib.optionals (stdenv.isWLLVM && !toolchainOnly) [
    "-DBUILD_SHARED_LIBS=ON"
  ] ++ stdenv.lib.optionals enableWasm [
   "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly"
  ] ++ stdenv.lib.optionals stdenv.isWLLVM [
    "-DHAVE_DLOPEN=NO"
  ];

  postInstall = ''
    ln -sv $out/bin/clang $out/bin/cpp
  ''
  # TODO: Move to separate output instead of deleting
  # TODO: Prevent building/installing these in the first place!
  # TODO: Check that we removed all references, this is fragile as-is!
  + stdenv.lib.optionalString (removeRuntimePythonDep) ''
    rm -f $out/bin/git-clang-format
    rm -f $out/bin/scan-view
    rm -f $out/share/clang/*.py
    rm -f $out/share/clang/*.applescript
    rm -rf $out/share/scan-view
  '' + stdenv.lib.optionalString (removeRuntimeLibXML2Dep) ''
    rm -f $out/bin/c-index-test
  '';
  linkCxxAbi = true;

  setupHook = ./all-setup-hook.sh;

  # Ensure everything needed for tests is built during buildPhase
  buildFlags = [ "all" "test-depends" ];

  postBuild = ''
    paxmark m bin/{lli,llvm-rtdyld}
    paxmark m unittests/ExecutionEngine/MCJIT/MCJITTests
    paxmark m unittests/ExecutionEngine/Orc/OrcJITTests
    paxmark m unittests/Support/SupportTests
    paxmark m bin/lli-child-target
  '';

  enableParallelBuilding = true;

  doCheck = !stdenv.isMusl;

  # XXX: Only run default check target for now...
  #  checkTarget = "check-all";


  passthru = {
    isClang = true;
    isGNU = false;
    inherit src release_version;
    # cc = stdenv.cc;
  } // stdenv.lib.optionalAttrs (stdenv.cc ? isGNU && stdenv.cc.isGNU) {
    inherit gcc;
    # gcc = stdenv.cc;
  };

#  meta = {
#    description = "Collection of modular and reusable compiler and toolchain technologies";
#    homepage    = http://llvm.org/;
#    license     = stdenv.lib.licenses.bsd3;
#    maintainers = with stdenv.lib.maintainers; [ lovek323 raskin viric ];
#    platforms   = stdenv.lib.platforms.all;
#  };
}
