#!/usr/bin/env perl

use strict;
use warnings;

use WebTools::PhedexSvc;

my $list    = shift || die qq|Usage: $0 list [dest_se]|;
my $dest_se = shift || qq|cmsdcache.pi.infn.it|;

my $svc = WebTools::PhedexSvc->new({ verbose => 0 });

printf "%112s %6s %6s\n", "Block", "Source", "Dest";

open INPUT, $list || die qq|failed to open $list, stopped|;
while (<INPUT>) {
  my ($block, $src_se) = (split);

  $svc->query({ se => $src_se });
  my $src_info = $svc->files($block);
  my @src_files = sort keys %$src_info;

  $svc->query({ se => $dest_se });
  my $dest_info = $svc->files($block);
  my @dest_files = sort keys %$dest_info;

  printf "%112s %6d %6d\n", $block, scalar @src_files, scalar @dest_files;
}
close INPUT;
__END__
