#!/usr/bin/env perl

package main;

use strict;
use warnings;
use Data::Dumper;

use WebTools::DataSvc::FileInfo;
use WebTools::DataSvc::Files;

my $verbose = 0;
sub main
{
  my $infile = shift;
  my $obj = WebTools::DataSvc::Files->new({ verbose => 0 });
  open INPUT, $infile || die qq|Failed to open $infile!|;
  while (<INPUT>) {
    print;
    chop;
    my $info = $obj->wget({
       node => q|T1_FR_CCIN2P3_Buffer|,
      block => $_
    });
    print Data::Dumper->Dump([$info], [qw/info/]) if $verbose;
    print join ("\n", sort keys %$info), "\n";
  }
  close INPUT;
}
my $infile = shift || die qq|Usage: $0 infile|;
main $infile;
