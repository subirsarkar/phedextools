#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

use BaseTools::Util qw/trim/;
use WebTools::PhedexSvc;

$| = 1;

my @files = qw/KIT_orphan_CSA08.txt KIT_orphan_Summer09.txt/;
sub usage
{
    print <<HEAD;
Match a list of LFNs against PhEDEx using the data svc

The command line options are

-v|--verbose        display debug information       (D=false)
-h|--help           show help on this tool and quit (D=false)
-i|--input          input LFN list in a file        (D=None)
-l|--phedex-lookup  use the PhEDEx datasvc          (D=false)
-c|--use-cache      use cached PhEDEx file list     (D=true)

Example usage:
perl -w $0 --input=lfn.list --verbose
HEAD

exit 0;
}

sub readOptions
{
  # Extract command line options
  GetOptions 'verbose!'     => \$verbose,
             'help!'        => \&usage,
             'inputn=s'    => \$pattern,
             't|max-time=i' => \$dmax,
             'l|max-lm=i'   => \$lmax,
             'dryrun!'      => \$dryrun;
}

sub main
{
  my $lookup = shift;
  # Phedex file list
  my $pinfo = {};
  if ($lookup) {
    my $params = { se => 'cmssrm-fzk.gridka.de', complete => 'y' };
    my $phsvc  = new WebTools::PhedexSvc({ verbose => 1 });
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
    my $file = q|phedex.list|;
    open INPUT, $file || die qq|Failed to open $file for reading|;
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
