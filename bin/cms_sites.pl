#!/usr/bin/env perl
package main;

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Copy;
use JSON;

use WebTools::PhedexSvc;
use BaseTools::Util qw/trim/;

our $verbose = 1;
our $jsonfile = shift || qq|./sites.json|;
our $tmpfile = qq|$jsonfile.tmp|;

sub main
{
  # create a PhedexSvc object and get the [node,id] mapping
  my $svc = WebTools::PhedexSvc->new({ verbose => 0 });
  my $nodemap;  
  eval {
    $nodemap = $svc->nodemap;
  };
  die $@ if $@;
  print STDERR Data::Dumper->Dump([$nodemap], [qw/nodemap/]) if $verbose;
  #my @sites = grep { (/^T2/ or /^T3/) and !/CAF/ } sort keys %$nodemap;
  my @sites = grep { /^T[1-3]/ and (!/CAF/ and !/Export/ and !/Buffer/)} sort keys %$nodemap;

  my $json = JSON->new(pretty => 1, delimiter => 1, skipinvalid => 1);
  my $jstxt = ($json->can('encode'))
    ? $json->encode({ 'items' => \@sites })
    : $json->objToJson({ 'items' => \@sites });

  open OUTPUT, qq|>$tmpfile| or die qq|Failed to open output file $tmpfile|;
  print OUTPUT $jstxt;
  close OUTPUT;

  print STDOUT join("\n", @sites), "\n";
  copy $tmpfile, $jsonfile or warn qq|Failed to copy $tmpfile to $jsonfile|;
}
main;
__END__
