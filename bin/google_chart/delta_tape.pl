#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Text::xSV;
use URI::GoogleChart;
use LWP::Simple qw/getstore/;

my $verbose = 0;
sub create_plot
{
  my ($aoa, $dtag, $timestamp) = @_;
  my $colmap = [
    'b0,lg,0,69AFFE,0,4978AF,1',
    'b1,lg,0,FC7171,0,AA4C4C,1',
    'b2,lg,0,BDFF93,0,84B267,1',
    'b3,lg,0,CC99FF,0,7E5F9E,1'
  ];
  my $bfill = 'c,lg,45,FFFAFA,0,F0F8FF,0.75';
  $bfill = join ('|', $bfill, @$colmap);
  my $title = $dtag. ' Tape Storage (TB) ['. $timestamp. ']';
  my $chart = URI::GoogleChart->new("horizontal-stacked-bars", 640, 300,
      data => $aoa,
      chbh => "a,20",
      margin => [10,20,15,10],
      chf => $bfill,
      chxt => 'y',
      # T1_DE_KIT|T1_ES_PIC|T1_FR_CCIN2P3|T1_IT_CNAF|T1_TW_ASGC|T1_UK_RAL|T1_US_FNAL
      chxl => '0:|T1_US_FNAL|T1_UK_RAL|T1_TW_ASGC|T1_IT_CNAF|T1_FR_CCIN2P3|T1_ES_PIC|T1_DE_KIT',
      chxs => '0,000066,13,-1,_,FF0000',
      chg  => '20,0',
      title => [$title, '000066', 18],
      range_show => "bottom",
      range_round => 0,
      label => ['delta data cust', 'delta data non-cust', 'delta mc cust', 'delta mc non-cust'],
      color => [qw(5892D4 DE6363 9CD179 9B75C3)],
      background => "transparent"
  );

  # save chart to a file
  getstore($chart, "delta_tape.png");
}
sub build_hash 
{
  my ($file, $tag, $info) = @_;

  my $csv = new Text::xSV;
  $csv->open_file($file);
  $csv-> read_header;

  my @sites = qw(T1_DE_KIT T1_ES_PIC T1_FR_CCIN2P3 T1_IT_CNAF T1_TW_ASGC T1_UK_RAL T1_US_FNAL);
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
sub main
{
  my $timestamp = shift;
  # Current week
  my $cwinfo = {};
  build_hash('data_acq_output.csv', 'data', $cwinfo);
  build_hash('mc_acq_output.csv', 'mc', $cwinfo);
  print Data::Dumper->Dump([$cwinfo], [qw/cwinfo/]) if $verbose;

  # Last week
  my $lwinfo = {};
  build_hash('data_acq_output_lw.csv', 'data', $lwinfo);
  build_hash('mc_acq_output_lw.csv', 'mc', $lwinfo);
  print Data::Dumper->Dump([$lwinfo], [qw/lwinfo/]) if $verbose;

  # Delta
  for my $site (sort keys %$cwinfo) {
    for my $tag qw(data mc) {
      for my $type ('custodial', 'non-custodial') {
        $cwinfo->{$site}{$tag}{$type} -= $lwinfo->{$site}{$tag}{$type};
      }
    }
  }  

  my $aoa = [];
  for my $tag qw(data mc) {
    for my $type ('custodial', 'non-custodial') {
      my $a = [];
      for my $site (sort keys %$cwinfo) {
        push @$a, $cwinfo->{$site}{$tag}{$type};
      }
      push @$aoa, $a;
    }
  }
  print Data::Dumper->Dump([$aoa], [qw/aoa/]);# if $verbose;
  create_plot($aoa, 'Delta', $timestamp);  
}
my $timestamp = shift || die qq|Usage: $0 timestamp|;
main $timestamp;
__END__
