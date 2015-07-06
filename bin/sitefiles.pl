#!/usr/bin/env perl

package main;

use strict;
use warnings;
use Data::Dumper;
use Term::ProgressBar;
use List::Util qw/min max/;

use WebTools::DataSvc::Blocks;
use WebTools::DataSvc::Files;
use WebTools::DataSvc::FileInfo;

sub main
{
  my $node = shift;
  my $bobj = new WebTools::DataSvc::Blocks({ verbose => 0 });
  my $info = $bobj->wget({
     node => $node
  });

  my $nblocks = scalar keys %$info;
  my $iblock = 0;
  my $next_update = -1;
  my $progress = new Term::ProgressBar({ name => sprintf (qq|Blocks: %d, processed|, $nblocks), 
                                          count => $nblocks, 
                                         remove => 1, 
                                            ETA => 'linear' });
  $progress->minor(0);
  my $it = max 1, int($nblocks/100);

  for my $block (keys %$info) {
    unless ( (++$iblock)%$it ) {
      $next_update = $progress->update($iblock) if $iblock >= $next_update;
    }
    my $fobj = new WebTools::DataSvc::Files({ verbose => 0 });
    my $info = $fobj->wget({
       node => $node,
      block => $block
    });
    print join ("\n", keys %$info), "\n";
  }
  $progress->update($iblock) if $iblock > $next_update;
}
my $node = shift || die qq|$0 node_name|;
main $node;
__END__
