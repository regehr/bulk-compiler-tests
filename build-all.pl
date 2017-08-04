#!/usr/bin/perl -w

use strict;

sub build($) {
    (my $p) = @_;
    open INF, "<template.nix" or die;
    open OUTF, ">new.nix" or die;
    while (my $line = <INF>) {
        $line =~ s/XXX/$p/g;
        print OUTF $line;
    }
    close INF;
    close OUTF;
    print "$p\n";
    my $r = system "nix-build new.nix > logs/$p.log 2>&1";
    open OF, ">>logs/$p.log" or die;
    if ($r == 0) {
	print OF "\n\n\nSUCCESS\n";
    } else {
	print OF "\n\n\nFAIL\n";
    }
    close OF;
}

open IN, "<all-packages.txt" or die;
while (my $f = <IN>) {
    chomp $f;
    build($f);
}
