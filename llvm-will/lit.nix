{ stdenv, pythonPackages, sources, mkVerSuffix }:

pythonPackages.buildPythonPackage rec {
  src = sources.llvm.src;
  name = "llvm-lit-${mkVerSuffix sources.llvm}";


  unpackPhase = ''
    unpackFile ${src}
    mv llvm-* llvm
    sourceRoot=$PWD/llvm/utils/lit

    # fix SOURCE_DATE_EPOCH
    updateSourceDateEpoch "$sourceRoot"
  '';
}
