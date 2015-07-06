#!/usr/bin/env perl

package main;

use strict;
use warnings;
use WebTools::DataSvc::FileInfo;

sub main
{
  my $infile = shift;
  my $obj = WebTools::DataSvc::FileInfo->new({ verbose => 0 });
  open INPUT, $infile || die qq|Failed to open $infile!|;
  while (<INPUT>) {
    chop;
    my $info = $obj->wget({ lfn => $_ });
    defined $info->{nodes} or next;
    print join(' ', $_, @{$info->{nodes}}), "\n";
  }
  close INPUT;
}
my $infile = shift || die qq|Usage: $0 infile|;
main $infile;
