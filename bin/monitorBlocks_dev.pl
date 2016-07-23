#!/usr/bin/env perl

use strict;
use warnings;
use POSIX qw/strftime/;
use Template::Alloy;

use PhEDEx::PhedexSvc;
use BaseTools::Util qw/writeHTML/;

our $htmlFile = qq|blockinfo.html|;
our $tmplFile = qq|blockinfo.html.tmpl|;

my $list = shift || die qq|Usage: $0 list [dest_se]|;
my $dest_se = shift || qq|cmsdcache.pi.infn.it|;

my $svc = PhEDEx::PhedexSvc->new({ verbose => 0 });

# Create the Template::Alloy object and create the html from template
my $tt = Template::Alloy->new(
   EXPOSE_BLOCKS => 1,
   RELATIVE      => 1,
   INCLUDE_PATH  => qq|./|,
   OUTPUT_PATH   => qq|./|
);
my $output = qq||;
my $outref = \$output;

# html header
$tt->process_simple(qq|$tmplFile/header|, {}, $outref)      or die $tt->error, "\n";
$tt->process_simple(qq|$tmplFile/table_start|, {}, $outref) or die $tt->error, "\n";

open INPUT, $list || die qq|failed to open $list, stopped|;
while (<INPUT>) {
  my ($block, $src_se) = (split);

  $svc->query({ se => $src_se });
  my $src_info = $svc->files($block);
  my @src_files = sort keys %$src_info;

  $svc->query({ se => $dest_se });
  my $dest_info = $svc->files($block);
  my @dest_files = sort keys %$dest_info;

  my $nsrc  = scalar @src_files;
  my $ndest = scalar @dest_files;
  my $ndiff = $nsrc - $ndest;
  my $ndest_class = ($ndiff>0) ? qq|red| : qq|default|;

  my $row = {
    block => $block, 
     nsrc => $nsrc, 
    ndest_class => $ndest_class,
    ndest => $ndest
  };
  $tt->process_simple(qq|$tmplFile/table_row|, $row, $outref) or die $tt->error, "\n";
}
close INPUT;

my $tstr = strftime("%Y-%m-%d %H:%M:%S", localtime(time()));
$tt->process_simple(qq|$tmplFile/table_end|, {}, $outref) or die $tt->error, "\n";
$tt->process_simple(qq|$tmplFile/footer|, {timestamp => $tstr}, $outref) or die $tt->error, "\n";

# template is processed in memory, now dump
writeHTML($htmlFile, $output);
__END__
