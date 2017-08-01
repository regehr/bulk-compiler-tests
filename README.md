## Getting Started

Build the latest LLVM from sources:

```
cd llvm
nix-build
```

## TODO

- make sure everything runs with Nix sandboxing turned on

- figure out why LLVM is getting built twice

- figure out how to get all users to get a specific version of nixpkgs

- start exploring hydra

- measure compiler coverage

- find a better way to get the list of packages to build

- filter out packages that
  * don't end up invoking LLVM; hack the clang driver a bit
  * fail for uninteresting reasons
  * fail when doCheck is set

- can probably just statically split up the list of packages among
  machines