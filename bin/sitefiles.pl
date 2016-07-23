#!/usr/bin/env perl

package main;

use strict;
use warnings;
use Data::Dumper;
use Term::ProgressBar;
use List::Util qw/min max/;

use PhEDEx::DataSvc::Blocks;
use PhEDEx::DataSvc::Files;

sub main
{
  my $node = shift;
  my $verbose = 1;
  my $bobj = PhEDEx::DataSvc::Blocks->new({ verbose => $verbose });
  my $blockinfo = $bobj->wget({ node => $node });

  my $nblocks = scalar keys %$blockinfo;
  my $iblock = 0;
  my $next_update = -1;
  my $progress = Term::ProgressBar->new({ name => sprintf (qq|Blocks: %d, processed|, $nblocks), 
                                         count => $nblocks, 
				        remove => 1, 
                                           ETA => 'linear' });
  $progress->minor(0);
  my $it = max 1, int($nblocks/100);

  for my $block (keys %$blockinfo) {
    unless ( (++$iblock)%$it ) {
      $next_update = $progress->update($iblock) if $iblock >= $next_update;
    }
    my $fobj = PhEDEx::DataSvc::Files->new({ verbose => $verbose });
    my $fileinfo = $fobj->wget({
       node => $node,
      block => $block
    });
    print join ("\n", keys %$fileinfo), "\n";
  }
  $progress->update($iblock) if $iblock > $next_update;
}
my $node = shift || die qq|$0 node_name|;
main $node;
__END__
