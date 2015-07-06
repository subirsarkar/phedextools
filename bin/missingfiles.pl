#!/usr/bin/env perl

package main;

use strict;
use warnings;
use Getopt::Long;

use WebTools::DataSvc::FileInfo;
use WebTools::DataSvc::MissingFiles;

my $verbose;
my $node;
my $group = q|AnalysisOps|; 

sub usage
{
    print <<HEAD;
Find the missing files from a Group subscription at a node

The command line options are

-v|--verbose        display debug information       (D=false)
-h|--help           show help on this tool and quit (D=false)
-n|--node           PhEDEx node (CMS site)          (D=None)
-g|--group          Physics/Ops groups              (D=AnalysisOps)

Example usage:
perl -w $0 --node=T2_IT_Pisa --verbose
HEAD

exit 0;
}

sub readOptions
{
  # Extract command line options
  GetOptions 'verbose!' => \$verbose,
                'help!' => \&usage,
               'node=s' => \$node,
              'group=s' => \$group;
  defined $node or warn q|>>> PhEDEx node not defined| and usage;
}

sub main
{
  readOptions;
 
  my $obj = WebTools::DataSvc::MissingFiles->new({ verbose => 0 });
  my $info = $obj->wget({ node => $node, group => $group });
  my @files = keys %$info;
  print join ("\n", @files), "\n";
  my $fobj = WebTools::DataSvc::FileInfo->new({ verbose => 0 });
  for my $lfn (@files) {
    my $info = $fobj->wget({ lfn => $lfn });
    print "\n";
    WebTools::DataSvc::FileInfo->pprint($info);
  }
}
main;
__END__
