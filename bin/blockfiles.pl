#!/usr/bin/env perl

package main;

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

#use WebTools::DataSvc::FileInfo;
use WebTools::DataSvc::Files;

# Command line options with Getopt::Long
our $verbose      = '';
our $help         = '';
our $node         = undef;
our $excl_replica = undef;

sub usage
{
    print <<HEAD;
Find files in a dataset/block

The command line options are

-v|--verbose            display debug information (D=false)
-h|--help               show help on this tool and quit (D=false)
-n|--node               CMS Site name/SE
-e|--exclusive-replica  Dataset available only at one site(D=flase)

Example usage:
perl -w $0 --node=T2_IT_Pisa /QCD_Pt300/Summer09-MC_31X_V3_7TeV_TrackingParticles-v1/GEN-SIM-RECO
HEAD

exit 0;
}

sub readOptions
{
  # Extract command line options
  GetOptions    'verbose!' => \$verbose,
                   'help!' => \&usage,
      'exclusive-replica!' => \$excl_replica,
                  'node=s' => \$node;
}

sub main
{
  readOptions;

  # Read the block name
  my $block = shift @ARGV;
  die q|>>> ERROR. Dataset block undefined!| unless defined $block;
  print ">>> Processing: $block\n";

  my $obj = WebTools::DataSvc::Files->new({ verbose => $verbose });
  my $attr = { block => qq|$block| };
  $attr->{node} = $node if defined $node;
  my $info = $obj->wget($attr);
  print Data::Dumper->Dump([$info], [qw/info/]) if $verbose;
  while (my ($lfn, $ni) = each %$info) {
    my $nodes = $ni->{nodes};
    next unless defined $nodes;
    next if (defined $excl_replica and scalar @$nodes > 1);
    print join(' ', $lfn, @$nodes), "\n";
  }
}
main;
__END__
