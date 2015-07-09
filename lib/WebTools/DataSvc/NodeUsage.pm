package WebTools::DataSvc::NodeUsage;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use base 'WebTools::DataSvc::Base';

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
  my $params = (defined $attr->{node}) ? qq|node=$attr->{node}| : undef;
  my $content = $self->content({ cmd => q|nodeusage|, options => $params });
  my $info = $content->{PHEDEX}{NODE}[0];
  $self->info($info);
}

1;
__END__
package main;
my $obj = WebTools::DataSvc::NodeUsage->new;
my $info = $obj->wget({ node => q|T2_IT_Pisa| });
$obj->show;
