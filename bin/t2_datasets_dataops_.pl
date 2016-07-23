#!/usr/bin/env perl
package main;

use strict;
use warnings;
use Data::Dumper;
use File::Basename;

use PhEDEx::DataSvc::Nodes;
use PhEDEx::DataSvc::Subscriptions;
use BaseTools::Util qw/trim/;

$| = 1;

my $verbose = 0;
sub main
{
  # create a PhedexSvc object and get the [node,id] mapping
  my $svc = PhEDEx::DataSvc::Nodes->new({ verbose => 0 });
  my $nodemap = $svc->wget;
  print STDERR Data::Dumper->Dump([$nodemap], [qw/nodemap/]) if $verbose;
  my @sites = grep { /^T2/ } sort keys %$nodemap;
  my $obj = PhEDEx::DataSvc::Subscriptions->new({ verbose => 0 });
  for (@sites) {
    my $info = $obj->wget({ node => $_, group => q|DataOps| });
    print STDERR Data::Dumper->Dump([$info], [qw/subscription/]) if $verbose;
    print "Site: $_\n";
    printf qq|\t%s %8s %s\n|, q|Files|, q|Size(GB)|, q|Dataset|;
    for my $dset ( sort { $info->{$b}{bytes} <=> $info->{$a}{bytes} } keys %$info ) {
      printf qq|\t%5d %8.2f %16s %s\n|, 
        $info->{$dset}{files}, 
        $info->{$dset}{bytes}/1024**3, 
        $info->{$dset}{group}, 
        $dset;
    }
  }
}
main;
__END__
