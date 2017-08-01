{ stdenv
, llvm
, cmake
, release_version
, mkVerSuffix
, sources
, doCheck ? false # XXX: Re-enable this when we update!
, lit
, gtest
}:

stdenv.mkDerivation rec {
  name = "llvm-lld-${mkVerSuffix sources.lld}";
  src = sources.lld.src;

  buildInputs = [ cmake llvm ] ++ stdenv.lib.optionals doCheck [ lit gtest ];

  enableParallelBuilding = true;

  passthru = {
    inherit release_version;
  };

  ### Testing bits, patching
  inherit doCheck;

  cmakeFlags = stdenv.lib.optional doCheck "-DLLVM_INCLUDE_TESTS=ON";

  patchPhase = stdenv.lib.optionalString doCheck ''
    sed -i 's,DEPENDS .*,DEPENDS lld LLDUnitTests,' test/CMakeLists.txt
    sed -i 's,LLVM_TOOLS_DIR,LLVM_RUNTIME_OUTPUT_INTDIR,' test/lit.site.cfg.in
  '';

  preCheck = ''
    ln -s ${llvm}/bin/* bin/
  '';

  checkTarget = "check-lld";

  meta = {
    description = "Collection of modular and reusable compiler and toolchain technologies";
    homepage    = http://llvm.org/;
    license     = stdenv.lib.licenses.bsd3;
    maintainers = with stdenv.lib.maintainers; [ lovek323 raskin viric ];
    platforms   = stdenv.lib.platforms.all;
  };
}
