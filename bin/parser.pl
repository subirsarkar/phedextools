#!/usr/bin/env perl
package main;

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

use File::Find;
use File::Basename;
use File::Copy;
use Math::BigInt;

use POSIX qw/strftime/;
use Template::Alloy;

use WebTools::PhedexSvc;
use BaseTools::Util qw/trim writeHTML/;

use constant MB2By => 1024**2;
use constant GB2By => 1.0*(1024**3);
use constant TB2By => 1.0*(1024**4);

# Command line options with Getopt::Long
our $verbose  = '';
our $help     = '';
our $htmlFile = q|request_detail.html|;
our $tmplFile = q|file.tmpl|;
our $nodename = q|T2_IT_Pisa|;

$| = 1; # autoflush

sub usage
{
  print <<HEAD;
Prepare an HTML file from the XML version

The command line options are

-v|--verbose    display debug information       (D=false)
-h|--help       show help on this tool and quit (D=false)
-o|--output     name of the output HTML file    (D=test.html)
-s|--se         name of the storage element     (D=T2_IT_Pisa)
-t|--template   name of the template file       (D=file.tmpl) 

Example usage:
perl -w $0 -o test.html -v
HEAD

  exit 0;
}

sub readOptions
{
  # Extract command line options
  GetOptions 'verbose!'     => \$verbose,
             'help!'        => \&usage,
             's|se=s'       => \$nodename,
             't|template=s' => \$tmplFile,
             'o|output=s'   => \$htmlFile;
  print STDERR join(",", $nodename, $htmlFile), "\n" if $verbose;
}

sub buildDictionary
{
  my ($dict, $name, $key, $value, $size, $time, $is_custodial) = @_;

  my $rinfo;
  if (exists $dict->{$key}{data}) {
    $rinfo = $dict->{$key}{data};
  }
  $rinfo->{$name} = [$value, $size, $time, $is_custodial];
  $dict->{$key}{data} = $rinfo;
}

sub extendDictionary
{
  my $dict = shift;
  while ( my ($key) = each %$dict ) {
    my $totalsize = 0; 
    my $ndset = 0;
    my $rinfo = $dict->{$key}{data};
    while (my ($name) = each %$rinfo) {
      $ndset++;
      $totalsize += $rinfo->{$name}[1]; 
    }
    $dict->{$key}{storage_tot} = $totalsize;
    $dict->{$key}{n_datasets}  = $ndset;
  }
}
sub buildPage
{
  my ($tt, $outref_full, $dict, $tag) = @_;
 
  $tt->process_simple(qq|$tmplFile/${tag}_header|, {}, $outref_full) or die $tt->error, "\n";
  my $hlabel = ($tag eq 'group') ? 'group'   : 'reqname';
  my $vlabel = ($tag eq 'group') ? 'reqname' : 'group';
  for my $key (sort { $dict->{$b}{storage_tot} <=> $dict->{$a}{storage_tot} } keys %$dict) 
  {
    my $row = 
    {
       n_datasets => $dict->{$key}{n_datasets},
      storage_tot => sprintf ("%-8.2f", $dict->{$key}{storage_tot}),
    };
    $row->{$hlabel} = $key;
    $tt->process_simple(qq|$tmplFile/${tag}_row_header|, $row, $outref_full) or die $tt->error, "\n";

    my $rinfo = $dict->{$key}{data};
    for my $name (sort { $rinfo->{$b}[1] <=> $rinfo->{$a}[1] } keys %$rinfo) 
    {
      my $row = 
      {
             dataset => $name, 
     	     $vlabel => $rinfo->{$name}[0],
                size => sprintf ("%-7.2f", $rinfo->{$name}[1]), 
             reqtime => strftime("%Y-%m-%d %H:%M:%S", localtime($rinfo->{$name}[2])),
        is_custodial => $rinfo->{$name}[3]
      };
      $tt->process_simple(qq|$tmplFile/${tag}_row_data|, $row, $outref_full) or die $tt->error, "\n";
    }
    $tt->process_simple(qq|$tmplFile/${tag}_row_footer|, {}, $outref_full) or die $tt->error, "\n";
  }
  $tt->process_simple(qq|$tmplFile/${tag}_footer|, {}, $outref_full) or die $tt->error, "\n";
}
sub buildFormat
{
   my ($q_subscribed, $q_atsite, $extra_tag) = @_; 
   $extra_tag = '' unless defined $extra_tag;

   my $class = ($q_atsite > 0) ? 'green' : 'grey';
   my $format = qq|<span class="$class">%d $extra_tag complete</span> / |;

   $class = ($q_subscribed == $q_atsite) ? 'grey' : 'red';
   $format .= qq|<span class="$class">%d $extra_tag missing</span>|;
}
sub main
{
  readOptions;

  # create a PhedexSvc object
  my $svc = WebTools::PhedexSvc->new({ verbose => 0 });

  #  get [node,id] mapping
  my $nodemap = $svc->nodemap;
  my $nodeid  = $nodemap->{$nodename}{id};

  # find dataset blocks, do restrict to only completed ones, 
  # however, exclude the ones not subscribed to
  $svc->options({ node => $nodename, subscribed => q|y| });
  my $blockList = $svc->blocks;

  my $storage_tot = 0;
  my $n_files = 0;
  my $av_dsets = {};
  while ( my ($name, $binfo) = each %$blockList ) {
    my $dataset = trim ((split /#/, $name)[0]);
    my $group = $binfo->{replica}{group} || 'undefined';
    print STDERR ">>> dataset=$dataset, group=$group\n" if $verbose;

    my $bytes_b = $binfo->{bytes};
    my $files_b = $binfo->{files};
    $av_dsets->{$dataset}{blocks}++;
    $av_dsets->{$dataset}{bytes} += $bytes_b;
    $av_dsets->{$dataset}{files} += $files_b;
    if ($binfo->{replica}{complete} eq 'y') {
      $av_dsets->{$dataset}{blocks_atsite}++;
      $av_dsets->{$dataset}{bytes_atsite} += $bytes_b;
      $av_dsets->{$dataset}{files_atsite} += $files_b;
    }
    push @{$av_dsets->{$dataset}{groups}}, $group
      unless grep { $_ eq $group } @{$av_dsets->{$dataset}{groups}};

    $n_files     += $files_b;
    $storage_tot += $bytes_b;
  }
  # Post initialize the 'atsite' quantities
  while ( my ($dataset) = each %$av_dsets ) {
    $av_dsets->{$dataset}{blocks_atsite} = 0 unless defined $av_dsets->{$dataset}{blocks_atsite};
    $av_dsets->{$dataset}{bytes_atsite}  = 0 unless defined $av_dsets->{$dataset}{bytes_atsite};
    $av_dsets->{$dataset}{files_atsite}  = 0 unless defined $av_dsets->{$dataset}{files_atsite};
  }
  print Data::Dumper->Dump([$av_dsets], [qw/av_dsets/]) if $verbose;

  # now reset options for subscriptions
  $svc->options({ node => $nodename });
  my $info = $svc->subscriptions;

  # now loop over the subscribed datasets from the request page
  my $userdict = {};
  my $groupdict = {};
  my @infoList = ();
  my $n_datasets = 0;
  for my $name (sort { $info->{$b}{request}{time} <=> $info->{$a}{request}{time} } keys %$info) {
    print STDERR ">>> Processing $name\n" if $verbose;
    unless (defined $av_dsets->{$name}{blocks} and $av_dsets->{$name}{blocks} > 0) {
      print STDERR qq|>> PhEDEx does not find any blocks/files for dataset $name\n| if $verbose;
      next;
    }

    my $blocks = (exists $info->{$name}{dbs}{blocks})
        ? scalar @{$info->{$name}{dbs}{blocks}}
        : $av_dsets->{$name}{blocks};
    my $files = $info->{$name}{dbs}{files};
    my $size  = $info->{$name}{dbs}{bytes};
    $size /= GB2By;
    my $replica_location = defined $info->{$name}{destination}{selist}
            ? join('|', @{$info->{$name}{destination}{selist}})
            : '';

    $n_datasets++;
    my $rid = $info->{$name}{request}{id};
    my $custodial = $info->{$name}{request}{custodial};
    my $header =
    {
                dataset => $name,
             request_id => $rid,
                 blocks => $blocks,
                  files => $files,
                   size => sprintf ("%-7.2f", $size),
           is_custodial => $custodial,
       replica_location => $replica_location
    };
    my $footer =
    {
           se => $nodename,
      dataset => $name,
       nodeid => $nodeid
    };
    my $coll =
    {
      header => $header,
      footer => $footer
    };
    my $rows = []; # actually dummy, just a single element

    my $reqname = $info->{$name}{requester}{name};
    my $reqtime = $info->{$name}{request}{time} || 0;
    my $apptime = $info->{$name}{approver}{time} || 0;
    my $groups  = $av_dsets->{$name}{groups};
    my $group   = $groups->[0];

    # dataset/block information
    my $blocks_subscribed = $av_dsets->{$name}{blocks};
    my $bytes_subscribed  = $av_dsets->{$name}{bytes};
    my $files_subscribed  = $av_dsets->{$name}{files};

    my $blocks_atsite = $av_dsets->{$name}{blocks_atsite};
    my $bytes_atsite  = $av_dsets->{$name}{bytes_atsite};
    my $files_atsite  = $av_dsets->{$name}{files_atsite};

    my $frac      = ($bytes_subscribed) ? $bytes_atsite/$bytes_subscribed : 0;
    my $frac_left = ($bytes_subscribed) ? ($bytes_subscribed - $bytes_atsite)/$bytes_subscribed : 0;

    my $ftag = ($bytes_atsite == 0 or ($bytes_subscribed == $bytes_atsite)) ? qq|%d| : qq|%.2f|;
    my $format = buildFormat($bytes_subscribed, $bytes_atsite, qq|MB ($ftag%%)|);
    my $site_status = sprintf $format, $bytes_atsite/MB2By,
                                       $frac*100,
                                       ($bytes_subscribed - $bytes_atsite)/MB2By,
                                       $frac_left*100;

    $format = buildFormat($blocks_subscribed, $blocks_atsite);
    my $block_status = sprintf $format, $blocks_atsite,
                                       ($blocks_subscribed - $blocks_atsite);

    $format = buildFormat($files_subscribed, $files_atsite);
    my $file_status = sprintf $format, $files_atsite,
                                       ($files_subscribed - $files_atsite);
    my $row =
    {
            reqname => $reqname,
            reqmail => $info->{$name}{requester}{email},
              reqid => $info->{$name}{requester}{id},
            reqtime => strftime("%Y-%m-%d %H:%M:%S", localtime($reqtime)),
         reqcomment => $info->{$name}{requester}{comments},
              group => $group,
            appname => $info->{$name}{approver}{name},
            appmail => $info->{$name}{approver}{email},
              appid => $info->{$name}{approver}{id},
            apptime => strftime("%Y-%m-%d %H:%M:%S", localtime($apptime)),
         appcomment => $info->{$name}{approver}{decision},
        dset_status => sprintf("%d MB in %d blocks %d files", $bytes_subscribed/MB2By,
                                                              $blocks_subscribed,
                                                              $files_subscribed),
        size_status => $site_status,
       block_status => $block_status,
        file_status => $file_status
    };
    push @$rows, $row;
    $coll->{requests} = $rows;

    # now for quickSearch
    my $qrow =
    {
           dataset => $name,
           reqname => $info->{$name}{requester}{email},
             group => $group,
              size => sprintf ("%-7.2f", $size),
              time => $reqtime,
           reqtime => strftime("%Y-%m-%d %H:%M:%S", localtime($reqtime)),
      is_custodial => $custodial
    };
    $coll->{qs} = $qrow;
    push @infoList, $coll;

    # prepare that extra bit for requester and group pages
    buildDictionary($userdict,  $name, $reqname, $group, $size, $reqtime, $custodial);
    buildDictionary($groupdict, $name, $group, $reqname, $size, $reqtime, $custodial);
  }
  # build group and user dictionaries further
  extendDictionary($userdict);
  extendDictionary($groupdict);

  # Create a Template::Alloy object
  my $tt = Template::Alloy->new(
    EXPOSE_BLOCKS => 1,
    RELATIVE      => 1,
    INCLUDE_PATH  => q|tmpl/|,
    OUTPUT_PATH   => q|./|
  );
  my $output_full = q||;
  my $outref_full = \$output_full;

  # html header
  my $tstr = strftime "%Y-%m-%d %H:%M:%S %Z", localtime(time);
  $tt->process_simple(qq|$tmplFile/header|,
    {
            site => $nodename,
       timestamp => $tstr
    }, $outref_full) or die $tt->error, "\n";

  # summary
  $storage_tot /= TB2By;
  $tt->process_simple(qq|$tmplFile/summary_header|,
    {
                site => $nodename,
                  se => $nodename,
       storage_total => sprintf ("%-7.2f", $storage_tot),
          n_datasets => $n_datasets,
             n_files => $n_files
    }, $outref_full) or die $tt->error, "\n";

  # loop over groups 
  my $groupinfo = $svc->groupusage;
  my $total_attr = {};
  for my $group ( sort { $groupinfo->{$b}{sbytes} <=> $groupinfo->{$a}{sbytes} } keys %$groupinfo) {
    # do not use exists/defined $groupdict->{$group}{n_datasets} which has an aliasing effect
    my $nset = (exists $groupdict->{$group}) ? $groupdict->{$group}{n_datasets} : 0;
    $total_attr->{subscribed_space} += $groupinfo->{$group}{sbytes};
    $total_attr->{resident_space}   += $groupinfo->{$group}{rbytes};
    $total_attr->{subscribed_files} += $groupinfo->{$group}{sfiles};
    $total_attr->{resident_files}   += $groupinfo->{$group}{rfiles};
    $total_attr->{dataset}          += $nset;
    my $row =
    {
                  group => $group,
       subscribed_space => sprintf ("%-8.2f", $groupinfo->{$group}{sbytes}/GB2By),
       subscribed_files => $groupinfo->{$group}{sfiles},
         resident_space => sprintf ("%-8.2f", $groupinfo->{$group}{rbytes}/GB2By),
         resident_files => $groupinfo->{$group}{rfiles},
                dataset => $nset
    };
    $tt->process_simple(qq|$tmplFile/summary_row|, $row, $outref_full) or die $tt->error, "\n";
  }
  my $row =
  {
                group => q|Total|,
     subscribed_space => sprintf ("%-8.2f", ($total_attr->{subscribed_space} || 0)/GB2By),
     subscribed_files => $total_attr->{subscribed_files} || 0,
       resident_space => sprintf ("%-8.2f", ($total_attr->{resident_space} || 0)/GB2By),
       resident_files => $total_attr->{resident_files} || 0,
              dataset => $total_attr->{dataset} || 0
  };
  $tt->process_simple(qq|$tmplFile/summary_footer|, $row, $outref_full) or die $tt->error, "\n";

  # now loop over dataset rows
  $tt->process_simple(qq|$tmplFile/dataset_header|, {site => $nodename}, $outref_full) or die $tt->error, "\n";
  for my $info (sort { $b->{header}{size} <=> $a->{header}{size} } @infoList) {
    $tt->process_simple(qq|$tmplFile/dataset_row_header|, $info->{header}, $outref_full) or die $tt->error, "\n";
    for my $row (@{$info->{requests}}) {
      $tt->process_simple(qq|$tmplFile/dataset_row_request|, $row, $outref_full) or die $tt->error, "\n";
    }
    $tt->process_simple(qq|$tmplFile/dataset_row_footer|, $info->{footer}, $outref_full) or die $tt->error, "\n";
  }
  # requester and group pages
  buildPage($tt, $outref_full, $userdict,  'requester');
  buildPage($tt, $outref_full, $groupdict, 'group');

  # Now build the quickSearch page with a simple table layout
  $tt->process_simple(qq|$tmplFile/qs_header|, {}, $outref_full) or die $tt->error, "\n";
  for my $coll (sort { $b->{qs}{time} <=> $a->{qs}{time} } @infoList) {
    my $qs = $coll->{qs};
    $tt->process_simple(qq|$tmplFile/qs_row|, $qs, $outref_full) or die $tt->error, "\n";
  }
  $tt->process_simple(qq|$tmplFile/qs_footer|, {}, $outref_full) or die $tt->error, "\n";

  # footer
  $tt->process_simple(qq|$tmplFile/footer|, {}, $outref_full) or die $tt->error, "\n";

  # template is processed in memory, now dump
  writeHTML($htmlFile, $output_full);
}

# subroutine definition done
main;
__END__
