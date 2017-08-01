#!/bin/sh

function error_exit {
  echo "ERROR: $1" 1>&2
  echo "Aborting."
  exit 1
}
which nix-prefetch-url >& /dev/null || \
  error_exit "Unable to find 'nix-prefetch-url', make sure you have nix installed and available!"

ROOT=$(readlink -f $(dirname $0)/..)
LLVM="$ROOT/pkgs/development/compilers/llvm/master"

BRANCH=${1:-master}
REF="refs/heads/$BRANCH"
SOURCES="$LLVM/sources/$BRANCH"
LOG="$SOURCES/summary.log"

URL="https://github.com/llvm-mirror"
APIURL="https://api.github.com/repos/llvm-mirror"

function getCommit() {
  git ls-remote "$URL/$1" "$2"|awk '{print $1}'
}

function prefetch() {
  nix-prefetch-url "$URL/$1/archive/$2.tar.gz" 2>/dev/null
}

function getsvnrev() {
  # Use github API to get commit message for a given hash without cloning,
  # then run through some grep/sed to extract the revision, hopefully.
  curl -s "$APIURL/$1/git/commits/$2" | grep '"message": '| grep "git-svn-id" | sed -e 's,.*git-svn-id:[^@]*@\([0-9]*\) .*,\1,'
}

function fixVersion() {
  name=$1
  ref=$2
  echo "$name: ($ref)"
  commit=$(getCommit $name $ref)
  echo -e "\tlatest commit:   $commit"
  sha=$(prefetch $name $commit)
  echo -e "\tprefetch-sha256: $sha"
  svnrev=$(getsvnrev $name $commit)
  echo -e "\tsvn rev: $svnrev"

  sources_file="$SOURCES/${name}.nix"
  cat > ${sources_file} << EOF
{
  name = "${name}";
  rev = "${commit}";
  sha256 = "${sha}";
  svn_rev = "${svnrev}";
}
EOF
}

:>$LOG
fixVersion clang $REF|& tee -a $LOG
fixVersion compiler-rt $REF|& tee -a $LOG
fixVersion clang-tools-extra $REF|& tee -a $LOG
fixVersion llvm $REF|& tee -a $LOG
fixVersion lld $REF|& tee -a $LOG
fixVersion libcxx $REF|& tee -a $LOG
fixVersion libcxxabi $REF|& tee -a $LOG
fixVersion libunwind $REF|& tee -a $LOG

max_svnrev=$(grep "svn rev: " $LOG|awk '{print $3}'|sort -n|tail -n1)
: >> $LOG
echo "max svn rev: ${max_svnrev}" |& tee -a $LOG
