linkCxxAbi="@linkCxxAbi@"
export NIX_CLANG_STDLIB_COMPILE+=" -isystem @out@/include/c++/v1"
export NIX_CLANG_STDLIB_LINK=" -stdlib=libc++${linkCxxAbi:+" -lc++abi"}"
