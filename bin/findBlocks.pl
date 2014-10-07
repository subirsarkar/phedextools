#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use WebTools::PhedexSvc;
use BaseTools::Util qw/trim/;

use constant DEBUG => 0;

my $list = shift || die qq|Usage: $0 list|;
open INPUT, $list || die qq|failed to open $list, stopped|;
while (<INPUT>) {
  my ($dataset, $frac, $src_se) = (split);
  $se = qq|cmssrm.fnal.gov| unless $src_se;
  print join(', ', $dataset, $frac, $src_se), "\n" if DEBUG;
  my $svc = WebTools::PhedexSvc->new({ verbose => 0 });
  $svc->query({ se => $src_se });
  my $blocks = $svc->blocks(trim($dataset));

  my @blist = sort keys %$blocks;
  $frac = 1.0 unless scalar @blist > 10;
  my $tfiles = 0;
  for my $key (@blist) {
    $tfiles += $blocks->{$key}[0];
  }
  my $nfiles = 0;
  for my $key (@blist) {
    $nfiles += $blocks->{$key}[0];
    last if $nfiles > int($frac*$tfiles);
    print "$key\n";
  }
  print "\n";
}
close INPUT;
__END__
