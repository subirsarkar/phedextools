package WebTools::DataSvc::Files;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use URI::Escape;

use base 'WebTools::DataSvc::Base';
use WebTools::DataSvc::Blocks;

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
  croak q|Neither dataset/block nor Node/SE specified!| 
    unless (defined $attr->{block} or defined $attr->{node} or defined $attr->{se});

  # handle the case only a dataset name is specified
  my @blockList = ();
  if (defined $attr->{block}) {
      my ($dset, $block) = split /#/, $attr->{block};
      if (defined $block) {
	  push @blockList, $attr->{block};
      }
  }
  unless (scalar @blockList) {
    my $br = WebTools::DataSvc::Blocks->new;
    my $info = $br->wget($attr);
    push @blockList, keys %$info;
  }
  print join("\n", @blockList), "\n" if $self->{_verbose};
  my $params = __PACKAGE__->params($attr, [
                  'node', 
                  'se', 
                  'update_since', 
                  'create_since',
                  'complete',
                  'dist_complete',
                  'subscribed',
                  'custodial',
		  'group'], 0);
  my $info = {};
  for my $block (@blockList) {  
    my $dset = (split /#/, $block)[0];

    # escape the offending # character in the blockname string
    $block = join (uri_escape("#"), (split /#/, $block));
    my $p = qq|block=| . $block . $params;

    # Note that we do not deal with the 'lfn'
    my $content = $self->content({ 
	    cmd => q|fileReplicas|, 
	options => $p,
        verbose => $self->{_verbose} 
    });

    my $files = $content->{PHEDEX}{BLOCK}[0]{FILE};
    for my $file (@$files) {
      print join(' ', '==> Fileinfo', $file->{NAME}, 
        $file->{BYTES}, join (' ', (split /,/, $file->{CHECKSUM}))), "\n" if $self->{_verbose};

      my $nodes = [];
      for my $replica (@{$file->{REPLICA}}) {
        push @$nodes, $replica->{NODE} if defined $replica->{NODE};
      }
      $info->{$file->{NAME}} = 
      {
           file => $file->{NAME},
           size => $file->{BYTES}, 
       checksum => $file->{CHECKSUM}, 
        dataset => $dset,
          block => uri_unescape($block),
          nodes => $nodes
      };
    }
  }
  $self->info($info);
}

1;
__END__
package main;
my $obj = WebTools::DataSvc::Files->new({ verbose => 1 });
my $info = $obj->wget({  
                    node => q|T2_IT_Pisa|, 
                   block => q|/MinimumBias/Commissioning10-Apr21Skim_356_PreProduction_SD_EG-v1/RECO|,
              subscribed => 1
           });
$obj->show;
