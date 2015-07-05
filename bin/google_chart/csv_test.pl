#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Text::xSV;

sub build_hash 
{
  my ($file, $tag, $info) = @_;

  my $csv = new Text::xSV;
  $csv->open_file($file);
  $csv-> read_header;

  my @sites = qw(T1_DE_KIT T1_IT_CNAF T1_ES_PIC T1_FR_CCIN2P3 T1_UK_RAL T1_US_FNAL T1_TW_ASGC);
  while ($csv->get_row()) {
    my ($acq_era,$type) = $csv->extract('Acquisition era', 'Cust./Non-Cust.');
    next unless defined $type;
    next unless $acq_era eq 'Total';
    my @values = $csv->extract(@sites);
    for my $site (@sites) {
      $info->{$site}{$tag}{$type} = shift @values;
    }
  }
}
my $info = {};
build_hash('data_acq_output.csv', 'data', $info);
build_hash('mc_acq_output.csv', 'mc', $info);
print Data::Dumper->Dump([$info], [qw/info/]);

my $aoa = [];
for my $site (sort keys %$info) {
  my $a = [
      $info->{$site}{data}{custodial},
      $info->{$site}{data}{'non-custodial'},
      $info->{$site}{mc}{custodial},
      $info->{$site}{mc}{'non-custodial'},
  ];
  push @$aoa, $a;
}
print Data::Dumper->Dump([$aoa], [qw/aoa/]);
__END__
