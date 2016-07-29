package PhEDEx::DataSvc::FilesBase;

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
sub verbose
{
  my $self = shift;
  $self->{_verbose} = shift if @_;
  $self->{_verbose};  
}
sub cmd
{
  my $self = shift;
  $self->{_cmd} = shift if @_;
  $self->{_cmd};  
}
sub tags
{
  my $self = shift;
  $self->{_tags} = shift if @_;
  $self->{_tags};  
}
sub wget
{
  my ($self, $attr) = @_;
  croak q|Neither dataset/block nor Node/SE specified!| 
    unless (defined $attr->{block} 
         or defined $attr->{node} 
         or defined $attr->{se});

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
  print join("\n", @blockList), "\n" if $self->verbose;

  my $params = __PACKAGE__->params($attr, $self->tags, 1);
  print $params, "\n";
  my $info = {};
  for my $block (@blockList) {   
    my $dset = (split /#/, $block)[0];
    
    # escape the offending # character in the blockname string
    $block = join (uri_escape("#"), (split /#/, $block));
    my $p = $params . qq|&block=$block|;

    # Note that we do not deal with the 'lfn'
    my $content = $self->content({ 
          cmd => $self->cmd, 
      options => $p, 
      verbose => $self->verbose
    });

    my $files = $content->{PHEDEX}{BLOCK}[0]{FILE};
    for my $file (@$files) {
      print join(' ', '>>> Fileinfo', $file->{NAME}, $file->{BYTES}, 
            join(' ', (split /,/, $file->{CHECKSUM}))), 
            "\n" if $self->verbose;
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
