## Getting Started

Build the latest LLVM from sources:

```
cd llvm
nix-build
```

## TODO

- find the latest rev of LLVM and check it out consistently, as
  opposed to separately checking out the head of all subprojects;
  see scripts from Will

- make sure everything runs with Nix sandboxing turned on

- figure out why LLVM is getting built twice

- figure out how to get all users to get a specific version of nixpkgs

- start exploring hydra
