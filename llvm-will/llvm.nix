{ stdenv
, perl
, groff
, cmake
, python
, libffi
, binutils
, libxml2
, ncurses
, release_version
, zlib
, sources
, llvm_patches
, mkVerSuffix
, debugVersion ? false
, enableSharedLibraries ? !stdenv.isDarwin
, overrideTriple ? null
, buildSlim ? false
, enableAssertions? true
, enableWasm ? true
, enableFFI ? !false && !buildSlim
}:

stdenv.mkDerivation rec {
  src = sources.llvm.src;
  name = "llvm-${mkVerSuffix sources.llvm}";

  unpackPhase = ''
    unpackFile ${src}
    chmod -R u+w llvm-*
    mv llvm-* llvm
    sourceRoot=$PWD/llvm
    unpackFile ${sources.compiler-rt.src}
    chmod -R u+w compiler-rt-*
    mv compiler-rt-* $sourceRoot/projects/compiler-rt
  '';

  buildInputs = [ perl groff cmake libxml2 python ]
    ++ stdenv.lib.optional enableFFI libffi;
  #    ++ stdenv.lib.optional stdenv.isDarwin libcxxabi;

  propagatedBuildInputs = [ ncurses zlib ];

  # hacky fix: New LLVM releases require a newer OS X SDK than
  # 10.9. This is a temporary measure until nixpkgs darwin support is
  # updated.
  ##patchPhase = stdenv.lib.optionalString stdenv.isDarwin ''
  ##      sed -i 's/os_trace(\(.*\)");$/printf(\1\\n");/g' ./projects/compiler-rt/lib/sanitizer_common/sanitizer_mac.cc
  ##'';

  patches = llvm_patches;

  cmakeFlags = with stdenv; [
    "-DCMAKE_BUILD_TYPE=${if debugVersion then "Debug" else "Release"}"
    ("-DLLVM_ENABLE_ASSERTIONS=" + (if enableAssertions then "ON" else "OFF"))
    "-DCOMPILER_RT_CAN_EXECUTE_TESTS=OFF" # Needed to build compiler-rt without clang
    "-DLLVM_INSTALL_UTILS=ON"  # Needed by rustc
    # "-DLLVM_ENABLE_FFI=${if enableFFI then "ON" else "OFF"}"
  ] ++ stdenv.lib.optionals buildSlim [
    "-DLLVM_ENABLE_FFI=OFF"
    "-DLLVM_ENABLE_RTTI=OFF"
    "-DLLVM_ENABLE_EH=OFF"
    "-DLLVM_ENABLE_BACKTRACES=OFF"
    # "-DLLVM_ENABLE_LIBCXX=ON"
    # "-DLLVM_ENABLE_LIBCXXABI=ON"
    "-DLLVM_ENABLE_TERMINFO=OFF"
    "-DLLVM_ENABLE_THREADS=OFF"
    "-DLLVM_ENABLE_ZLIB=OFF"
    "-DLLVM_TARGETS_TO_BUILD=host"
    #    "-DLLVM_BUILD_STATIC=ON"
    "-DGCC_INSTALL_PREFIX=GCC-NOTFOUND"
  ] ++ stdenv.lib.optionals (!buildSlim) [
    "-DLLVM_BUILD_TESTS=ON"
    "-DLLVM_ENABLE_FFI=${if enableFFI then "ON" else "OFF"}"
    "-DLLVM_ENABLE_RTTI=ON"
  ] ++ stdenv.lib.optionals enableSharedLibraries [
    "-DLLVM_LINK_LLVM_DYLIB=OFF"
    "-DBUILD_SHARED_LIBS=ON"
  ] ++ stdenv.lib.optional (!isDarwin)
    "-DLLVM_BINUTILS_INCDIR=${binutils.dev}/include"
    ++ stdenv.lib.optionals ( isDarwin) [
    "-DLLVM_ENABLE_LIBCXX=ON"
    "-DCAN_TARGET_i386=false"
  ] ++ stdenv.lib.optionals (overrideTriple != null) [
    "-DLLVM_HOST_TRIPLE=${overrideTriple}"
    "-DLLVM_DEFAULT_TARGET_TRIPLE=${overrideTriple}"
    "-DTARGET_TRIPLE=${overrideTriple}"
  ] ++ stdenv.lib.optionals (false) [
    "-DCOMPILER_RT_BUILD_SANITIZERS=OFF"
    "-DCOMPILER_RT_BUILD_XRAY=OFF"
  ] ++ stdenv.lib.optionals enableWasm [
   "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly"
  ] ++ stdenv.lib.optionals false [
    "-DHAVE_DLOPEN=NO"
  ];


  postBuild = ''
    paxmark m bin/{lli,llvm-rtdyld}
  '';

  enableParallelBuilding = true;

  passthru = {
    inherit src release_version;
  };

  meta = {
    description = "Collection of modular and reusable compiler and toolchain technologies";
    homepage    = http://llvm.org/;
    license     = stdenv.lib.licenses.bsd3;
    maintainers = with stdenv.lib.maintainers; [ lovek323 raskin viric ];
    platforms   = stdenv.lib.platforms.all;
  };
}
