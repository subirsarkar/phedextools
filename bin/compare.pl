#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;

my $p_filelist = q|phedex.list|;
my $s_filelist = q|20100722_store_PIC.txt|;

sub save 
{
  my ($file, $list) = @_;
  my $fh = IO::File->new($file, 'w');
  die qq|Failed to open $file, $!| unless (defined $fh && $fh->opened);
  print $fh join ("\n", @$list), "\n";
  $fh->close;
}

sub compare
{
  # phedex file list
  my $pinfo = {};
  open INPUT, $p_filelist or die qq|Failed to open input file $p_filelist|; 
  while (<INPUT>) {
    chop;
    $pinfo->{$_}++;
  }
  close INPUT;

  # Site file list
  my $sinfo = {};
  open INPUT, $s_filelist or die qq|Failed to open input file $s_filelist|; 
  while (<INPUT>) {
    chop;
    $sinfo->{$_}++;
  }
  close INPUT;

  # find phedex only files
  my $list = [];
  while ( my ($file) = each %$pinfo) {
    push @$list, $file unless exists $sinfo->{$file};
  }
  save('ponly.list', $list);

  # now find phedex only files
  $list = [];
  while ( my ($file) = each %$sinfo) {
    push @$list, $file unless exists $pinfo->{$file};
  }
  save('sonly.list', $list);
}
compare;
__END__
