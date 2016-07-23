#!/usr/bin/env perl

package main;

use strict;
use warnings;
use PhEDEx::DataSvc::Files;

sub main
{
  my $infile = shift;
  my $obj = PhEDEx::DataSvc::Files->new({ verbose => 0 });
  open INPUT, $infile || die qq|Failed to open $infile!|;
  while (<INPUT>) {
    chop;
    my $info = $obj->wget({ lfn => $_ });
    my $nodes = $info->{nodes};
    next unless defined $nodes;
    next if scalar @$nodes > 1;
    print join(' ', $_, $nodes->[0]), "\n";
  }
  close INPUT;
}
my $infile = shift || die qq|Usage: $0 infile|;
main $infile;
