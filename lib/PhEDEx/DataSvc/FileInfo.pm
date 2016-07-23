package PhEDEx::DataSvc::FileInfo;

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
  croak q|An LFN must be specified| unless defined $attr->{lfn};

  my $params = __PACKAGE__->params($attr, [
                  'lfn',
                  'node', 
                  'se', 
                  'subscribed'], 0);
  my $content = $self->content({ cmd => q|fileReplicas|, options => $params });

  my $bname = $content->{PHEDEX}{BLOCK}[0]{NAME};
  carp qq|>>> ERROR. No block found for the $attr->{lfn}| 
    and return {} unless defined $bname;
  my $dset  = (split /#/, $bname)[0];
  my $file  = $content->{PHEDEX}{BLOCK}[0]{FILE}[0];
  my $nodes = [];
  for my $replica (@{$file->{REPLICA}}) {
    push @$nodes, $replica->{NODE} if defined $replica->{NODE};
  }
  print join(' ', $file->{NAME}, 
                  $file->{BYTES}), "\n" if $self->{_verbose};
  my $info = 
  {
        file => $file->{NAME},
        size => $file->{BYTES}, 
    checksum => $file->{CHECKSUM}, 
     dataset => $dset,
       block => uri_unescape($bname),
       nodes => $nodes
  };
  $self->info($info);
}

sub pprint
{
  my ($pkg, $info) = @_;
  return unless defined $info->{file};
  my $nodes = (defined $info->{nodes}) ? '[' . join (', ', @{$info->{nodes}}) . ']' : '';
  print <<"EOD";
lfn: <$info->{file}>
   dataset: $info->{dataset}
     block: $info->{block}
      size: $info->{size}
  checksum: $info->{checksum}
     nodes: $nodes
EOD
}

1;
__END__
package main;
my $obj = new PhEDEx::DataSvc::FileInfo({ verbose => 1 });
my $info = $obj->wget({  
         lfn => qq|/store/mc/Spring10/MinBias_TuneD6T_7TeV-pythia6/GEN-SIM-RECO/START3X_V26B-v1/0011/768322A3-1F5E-DF11-B020-003048CDCD46.root|,
  subscribed => 'y'
});
$obj->show;
