package PhEDEx::DataSvc::NodeUsageHistory;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use base 'PhEDEx::DataSvc::Base';

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
  croak qq|Node must be specified!| unless defined $attr->{node};

  my $params = qq|node=$attr->{node}|;
  for my $tag (qw/starttime endtime binwidth/)
  {
    $params .= qq|&$tag=$attr->{$tag}| if defined $attr->{$tag};
  }
  my $content = $self->content({ cmd => q|nodeusagehistory|, options => $params });
  my $info = $content->{PHEDEX}{NODE}[0]->{USAGE}[0];
  $self->info($info);
}

1;
__END__
package main;
my $obj = PhEDEx::DataSvc::NodeUsageHistory->new;
my $info = $obj->wget({ node => q|T2_IT_Pisa| });
$obj->show;
