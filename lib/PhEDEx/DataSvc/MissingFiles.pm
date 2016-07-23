package PhEDEx::DataSvc::MissingFiles;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use URI::Escape;

use base 'PhEDEx::DataSvc::Base';
use PhEDEx::DataSvc::Blocks;

sub new
{
  my ($this, $attr) = @_;
  my $class = ref $this || $this;

  my $self = $class->SUPER::new($attr);
  $self->{_verbose} = $attr->{verbose} || 0;
  bless $self, $class;
}
sub wget
{
  my ($self, $attr) = @_;
  carp qq|Neither Nodename nor SE specified, will take long| 
    unless (defined $attr->{node} or defined $attr->{se});

  # handle the case only a dataset name is specified
  my @blockList = ();
  if (defined $attr->{block}) {
      my ($dset, $block) = split /#/, $attr->{block};
      if (defined $block) {
	  push @blockList, $attr->{block};
      }
  }
  unless (scalar @blockList) {
    my $br = PhEDEx::DataSvc::Blocks->new;
    $br->wget($attr);
    push @blockList, keys %{$br->info};
  }
  my $params = '';
  for my $tag (qw/node 
                  se 
                  subscribed
                  custodial
                  group
               /)
  {
    $params .= qq|&$tag=$attr->{$tag}| if defined $attr->{$tag};
  }
  my $info = {};
  for my $block (@blockList) {  
    my $dset = (split /#/, $block)[0];

    # escape the offending # character in the blockname string
    $block = join (uri_escape("#"), (split /#/, $block));
    my $p = qq|block=|.$block.$params;

    # Note that we do not deal with the 'lfn'
    my $content = $self->content({ cmd => q|missingfiles|, options => $p });

    my $files = $content->{PHEDEX}{BLOCK}[0]{FILE};
    for my $file (@$files) {
      print '>>> FileInfo: '. join(' ', $file->{NAME}, $file->{BYTES}, 
                              join(' ', split (/,/, $file->{CHECKSUM}))), 
                              "\n" if $self->{_verbose};
      $info->{$file->{NAME}} = 
      {
           file => $file->{NAME},
           size => $file->{BYTES}, 
       checksum => $file->{CHECKSUM},
        dataset => $dset,
          block => uri_unescape($block)
      };
    }
  }
  $self->info($info);
  $self;
}

1;
__END__
package main;
my $obj = PhEDEx::DataSvc::MissingFiles->new;
$obj->wget({      node => q|T2_IT_Pisa|, 
                 block => q|/Cosmics/CRUZET4_v1_CRZT210_V1_TrackerPointing_v1/RECO|,
            subscribed => q|y|
          });
$obj->show;