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
  croak qq|Nodename or SE must be specified| 
    unless (defined $attr->{node} or defined $attr->{se});
  croak qq|dataset/block must be specified| unless defined $attr->{block};

  # handle the case only a dataset name is specified
  my ($dset, $block) = split /#/, $attr->{block};
  my @blockList = ();
  if (defined $block) {
    push @blockList, $attr->{block};
  }
  else {
    my $br = new WebTools::DataSvc::Blocks;
    my $info = $br->wget($attr);
    push @blockList, keys %$info;
  }
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
    # escape the offending # character in the blockname string
    $block = join (uri_escape("#"), (split /#/, $block));
    my $p = qq|block=| . $block . $params;

    # Note that we do not deal with the 'lfn'
    my $content = $self->content({ cmd => q|fileReplicas|, options => $p });

    my $files = $content->{PHEDEX}{BLOCK}[0]{FILE};
    for my $file (@$files) {
      print join(' ', $file->{NAME}, 
                      $file->{BYTES}), "\n" if $self->{_verbose};
      $info->{$file->{NAME}} = 
      {
           size => $file->{BYTES}, 
        dataset => $dset,
          block => uri_unescape($block)
      };
    }
  }
  $self->info($info);
}

1;
__END__
package main;
my $obj = new WebTools::DataSvc::Files({ verbose => 1 });
my $info = $obj->wget({  
                    node => q|T2_IT_Pisa|, 
                   block => q|/MinimumBias/Commissioning10-Apr21Skim_356_PreProduction_SD_EG-v1/RECO|,
              subscribed => 1
           });
$obj->show;
