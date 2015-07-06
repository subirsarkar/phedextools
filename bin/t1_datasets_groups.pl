#!/usr/bin/env perl
package main;

use strict;
use warnings;
use Data::Dumper;
use File::Basename;

use WebTools::DataSvc::Nodes;
use WebTools::DataSvc::Subscriptions;
use BaseTools::Util qw/trim/;

$| = 1;

my $verbose = 0;
sub main
{
  # create a PhedexSvc object and get the [node,id] mapping
  my $svc = WebTools::DataSvc::Nodes->new({ verbose => 0 });
  my $nodemap = $svc->wget;
  print STDERR Data::Dumper->Dump([$nodemap], [qw/nodemap/]) if $verbose;
  my @sites = grep { /^T1_\S+_MSS/ and !/CERN/ } sort keys %$nodemap;
  my $obj = WebTools::DataSvc::Subscriptions->new({ verbose => 0 });
  for (@sites) {
    my $info = $obj->wget({ node => $_ });
    print STDERR Data::Dumper->Dump([$info], [qw/subscription/]) if $verbose;
    print "Site: $_\n";
    printf qq|\t%s %8s %16s %s\n|, q|Files|, q|Size(GB)|, q|Group|, q|Dataset|;
    my $total_i = {};
    for my $dset ( sort { $info->{$b}{bytes} <=> $info->{$a}{bytes} } keys %$info ) {
      my $group = $info->{$dset}{subscription}{group} || $info->{$dset}{blocks}[0]{subscription}{group};
      defined $group or $group = 'undef';
      next if $group eq 'DataOps';
      printf qq|\t%5d %8.2f %16s %s\n|, 
        $info->{$dset}{files}, 
        $info->{$dset}{bytes}/1024**3, 
        $group, 
        $dset;
      $total_i->{dsets}++;
      $total_i->{files} += $info->{$dset}{files};
      $total_i->{bytes} += $info->{$dset}{bytes};
    }
    printf qq|\t%7s %8s %8s\n|, q|Files|, q|Size(TB)|, q|Datasets|;
    printf qq|\t%7d %8.2f %8d\n|, 
      $total_i->{files}, 
      $total_i->{bytes}/1024**4, 
      $total_i->{dsets};
  }
}
main;
__END__
