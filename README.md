## Getting Started

Build the latest LLVM from sources:

```
cd llvm
nix-build
```

## TODO

- find the latest rev of LLVM and check it out consistently, as
  opposed to separately checking out the head of all subprojects;
  see scripts from Will; get checksums back into the nix code

- make sure everything runs with Nix sandboxing turned on

- figure out why LLVM is getting built twice

- figure out how to get all users to get a specific version of nixpkgs

- start exploring hydra

- compiler coverage

- filter out packages that
  * don't end up invoking LLVM; hack the clang driver a bit
  * fail for uninteresting reasons

- can probably just statically split up the list of packages among
  machines