#!/usr/bin/perl -w

use strict;

my @good;
my @bad;

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
    my $ret = $r >> 8;
    if ($ret == 0) {
        push @good, $p;
    } else {
        push @bad, $p;
    }
}

open IN, "<all-packages.txt" or die;
while (my $f = <IN>) {
    chomp $f;
    build($f);
}

print "\ngood: ";
foreach my $p (@good) {
    print "  $p\n";
}

print "\nbad: ";
foreach my $p (@bad) {
    print "  $p\n";
}
