#!/usr/bin/env perl

use strict;
use warnings;
use PhEDEx::PhedexSvc;

my $dataset = shift || die qq|Usage: $0 dataset [se]|;
my $se      = shift || qq|cmsdcache.pi.infn.it|;

my $svc = PhEDEx::PhedexSvc->new({ verbose => 0 });
$svc->query({ se => $se });
my $files = $svc->files($dataset);
print join ("\n", sort keys %$files), "\n";
__END__
