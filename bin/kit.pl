#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use BaseTools::Util qw/trim/;
use PhEDEx::PhedexSvc;

$| = 1;

my @files = qw/KIT_orphan_CSA08.txt KIT_orphan_Summer09.txt/;
my $phedex_list = q|phedex.list|; # cached phedex file list

sub main
{
  my $lookup = shift;

  # Phedex file list
  my $pinfo = {};
  if ($lookup) {
    my $params = { se => 'cmssrm-fzk.gridka.de', complete => 'y' };
    my $phsvc  = PhEDEx::PhedexSvc->new({ verbose => 0 });
    $phsvc->options($params);
    my @list = ();
    my $blocks = $phsvc->blocks;
    while ( my ($bname) = each %$blocks ) {
      next unless ($bname =~ /CSA08/ or $bname =~ /Summer09/);
      my $info = {};
      $phsvc->_filesPerBlock($bname, $info);
      push @list, keys %$info;
    }
    %$pinfo = map { $_ => 1 } @list;
  }
  else {
    open INPUT, $phedex_list || die qq|Failed to open $phedex_list for reading|;
    while (<INPUT>) {
      $pinfo->{trim $_}++;
    }
    close INPUT;
  }
  print Data::Dumper->Dump([$pinfo], [qw/pinfo/]);

  # Prepare the input list and check
  print "====================== Decision ===============================\n";
  for my $file (@files) {
    open INPUT, $file || die qq|Failed to open $file for reading|;
    while (<INPUT>) {
      my $lfn = (split /\s+/)[-1];
      next unless exists $pinfo->{$lfn};
      print $lfn, "\n";
    }
    close INPUT;
  }
}
my $lookup = shift || 0;
main $lookup;
__END__
Usage: perl -w kit.pl 1 <-  in case you want to lookup phedex datasvc
       perl -w kit.pl 0 <-  you already have the phedex list cached as 'phedex.list'
