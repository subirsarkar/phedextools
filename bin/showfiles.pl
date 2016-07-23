#!/usr/bin/env perl

package main;

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use IO::File;

use PhEDEx::DataSvc::Files;

# Command line options with Getopt::Long
our $verbose      = '';
our $help         = '';
our $node         = undef;

sub usage
{
    print <<HEAD;
Find files in a dataset/block

The command line options are

-v|--verbose            display debug information (D=false)
-h|--help               show help on this tool and quit (D=false)
-n|--node               CMS Site name/SE

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
                  'node=s' => \$node;
}

sub main
{
  readOptions;

  # Read the block name
  my $block = shift @ARGV;
  die q|>>> ERROR. Dataset block undefined!| unless defined $block;
  print ">>> Processing: $block\n";

  my $obj = PhEDEx::DataSvc::Files->new({ verbose => $verbose });
  my $attr = { block => qq|$block| };
  $attr->{node} = $node if defined $node;
  my $info = $obj->wget($attr);
  print Data::Dumper->Dump([$info], [qw/info/]) if $verbose;

  my $filename = qq|files.list|;
  my $fh = IO::File->new($filename, 'w');
  die qq|Failed to open $filename, $!, stopped| unless ($fh && $fh->opened);
  for my $key (keys %$info) {
    print $fh join(":", $key, $info->{$key}{size}), "\n";
  }
  $fh->close;
}
main;
__END__
