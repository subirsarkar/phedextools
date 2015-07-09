package WebTools::DataSvc::TransferQueueHistory;

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
  croak qq|Either of source and destination must be specified!| 
    unless (defined $attr->{from} or defined $attr->{to});

  croak qq|Both source and destination may not be specified!| 
    if (defined $attr->{from} and defined $attr->{to});

  my $params = '';
  for my $tag (qw/from to starttime endtime binwidth/)
  {
    $params .= qq|&$tag=$attr->{$tag}| if defined $attr->{$tag};
  }
  $params =~ s/^&//;
  my $content = $self->content({ cmd => q|transferqueuehistory|, options => $params });
  my $links = $content->{PHEDEX}{LINK};
  my $info = {};
  for my $link (@$links) {
    my $f = (defined $attr->{to}) ? $link->{FROM} : $link->{TO};
    $info->{$f} = $link->{TRANSFERQUEUE};
  }
  $self->info($info);
}

1;
__END__
package main;
my $obj = WebTools::DataSvc::TransferQueueHistory->new({ instance => q|debug| });
my $info = $obj->wget({ from => q|T2_IT_Pisa| });
$obj->show;
