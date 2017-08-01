{ stdenv, cmake, fetch_v, libcxx, libunwind, llvm, version, libcxxabi_version, useMusl ? false, useLibCXX ? false, libcxxStatic ? false }:

stdenv.mkDerivation {
  # version = "${version}-${builtins.substring 0 7 libcxxabi_version}";
  # name = "libc++abi-${self.version}";
  name = "libc++abi-${version}-${builtins.substring 0 7 libcxxabi_version}";

  buildInputs = [ cmake ] ++ stdenv.lib.optional (!stdenv.isDarwin && !stdenv.isFreeBSD) libunwind.out;

  postUnpack = ''
    unpackFile ${libcxx.src}
    unpackFile ${llvm.src}
    export NIX_CFLAGS_COMPILE+=" -I$PWD/include"
    export NIX_LDFLAGS+=" -L${libunwind.out}/lib -lunwind"
    export cmakeFlags="" # start empty, because that's what was done before.
  '' + stdenv.lib.optionalString (libcxxStatic) ''
    export cmakeFlags+=" -DLIBCXXABI_ENABLE_STATIC=1 -DLIBCXXABI_ENABLE_SHARED=0"
  '' + stdenv.lib.optionalString (stdenv ? cross) ''
    export cmakeFlags+=" -DLIBCXXABI_TARGET_TRIPLE=${stdenv.cross.config}"
  '' + stdenv.lib.optionalString stdenv.isDarwin ''
    export TRIPLE=x86_64-apple-darwin
  '' + stdenv.lib.optionalString (useMusl) ''
    export NIX_CFLAGS_COMPILE+=" -D_LIBCPP_HAS_MUSL_LIBC=1"
  '' + stdenv.lib.optionalString (true) ''
    export cmakeFlags+=" -DLLVM_PATH=$PWD/$(ls -d llvm-*) -DLIBCXXABI_LIBCXX_INCLUDES=$PWD/$(ls -d libcxx-*)/include"
  '';

  installPhase = if stdenv.isDarwin
    then ''
      for file in lib/*.dylib; do
        # this should be done in CMake, but having trouble figuring out
        # the magic combination of necessary CMake variables
        # if you fancy a try, take a look at
        # http://www.cmake.org/Wiki/CMake_RPATH_handling
        install_name_tool -id $out/$file $file
      done
      make install
      install -d 755 $out/include
      install -m 644 ../include/*.h $out/include
    ''
    else ''
      install -d -m 755 $out/include $out/lib
      if [ -e lib/libc++abi.so.1.0 ]; then
        install -m 644 lib/libc++abi.so.1.0 $out/lib
        ln -s libc++abi.so.1.0 $out/lib/libc++abi.so
        ln -s libc++abi.so.1.0 $out/lib/libc++abi.so.1
      fi
      install -m 644 lib/libc++abi.a $out/lib
      install -m 644 ../include/cxxabi.h $out/include
    '';

  meta = {
    homepage = http://libcxxabi.llvm.org/;
    description = "A new implementation of low level support for a standard C++ library";
    license = "BSD";
    maintainers = with stdenv.lib.maintainers; [ vlstill ];
    platforms = stdenv.lib.platforms.unix;
    broken = true;
  };
}
