package PhEDEx::DataSvc::Nodes;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use base q|PhEDEx::DataSvc::Base|;

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
  my $params = q||;
  if (defined $attr->{nodes}) {
    for my $node (@{$attr->{nodes}}) {
      $params .= qq|&node=$node|;
    }
  }
  $params .= qq|&noempty=1| if defined $attr->{noempty};
  $params =~ s/^&//;
  my $content = $self->content({ cmd => q|nodes|, options => $params });
  my $info = {};
  my $list = $content->{PHEDEX}{NODE};
  for my $node (@$list) {
    print join(' ', $node->{NAME} || q|?|, 
                    $node->{ID} || -1, 
                    $node->{SE} || q|?|, 
                    $node->{TECHNOLOGY} || q|?|,
                    $node->{KIND} || q|?|), 
        "\n" if $self->{_verbose};
    my $name = delete $node->{NAME};
    $info->{$name} = $node;
  }
  $self->info($info);
}

1;
__END__
