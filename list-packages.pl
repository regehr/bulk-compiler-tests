#!/usr/bin/perl -w

use strict;

my %pkgs;

open INF, "</nix/store/k0f936c324qyafs9m68ahihgb520a6bd-nixpkgs-17.09pre111388.00512470ec/nixpkgs/pkgs/top-level/all-packages.nix" or die;
while (my $line = <INF>) {
    next unless $line =~ /\s*(.*) = callPackage/;
    my $p = $1;
    next if ($p =~ /\"/);
    next if ($p =~ /\#/);
    $pkgs{$p} = 1;
}
close INF;

foreach my $k (sort keys %pkgs) {
    print "$k\n";
}
