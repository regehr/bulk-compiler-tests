{ stdenv, sources, mkVerSuffix
, pythonPackages, binutils, makeWrapper }:

assert !pythonPackages.isPy3k;

stdenv.mkDerivation rec {
  src = sources.llvm.src;
  name = "llvm-opt-viewer-${mkVerSuffix sources.llvm}";

  unpackPhase = ''
    unpackFile ${src}
    mv llvm-* llvm
    sourceRoot=$PWD/llvm/utils/opt-viewer
  '';

  buildInputs = [
    makeWrapper
    pythonPackages.wrapPython
    binutils
  ];

  pythonPath = with pythonPackages; [
    pygments
    pyyaml
  ];

  patchPhase = ''
    substituteInPlace opt-viewer.py \
      --replace 'c++filt' '${stdenv.lib.getBin binutils}/bin/c++filt'
  '';

  installPhase = ''
    mkdir -p $out/share/llvm $out/bin
    cp opt-viewer.py style.css $out/share/llvm/

    wrapPythonPrograms
    ln -s $out/share/llvm/opt-viewer.py $out/bin/opt-viewer
  '';
}
