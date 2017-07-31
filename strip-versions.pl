#!/usr/bin/perl -w

use strict;

my %done;
my %good;

sub test($) {
    (my $line) = @_;
    return if $done{$line};
    $done{$line} = 1;
    my $res = system "nix-env -i $line >/dev/null 2>&1";
    print "$line $res\n";
    if ($res == 0) {
        $good{$line} = 1;
    }
}

open INF, "<nixqa.txt" or die;
while (my $line = <INF>) {
    chomp $line;
    if ($line =~ /^(.*)\-[0-9]/) {
        my $n = $1;
        test($n);
    } elsif ($line =~ /^(.*)\-v[0-9]/) {
        my $n = $1;
        test($n);
    } elsif ($line =~ /^(.*)\_[0-9]/) {
        my $n = $1;
        test($n);
    } else {
        test($line);
    }
}
close INF;

open OUTF, ">all-packages.txt" or die;
foreach my $k (sort keys %good) {
    print OUTF "$k\n";
}
close OUTF;
