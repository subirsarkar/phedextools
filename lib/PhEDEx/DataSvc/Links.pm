package PhEDEx::DataSvc::Links;

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
  croak q|Either of source and destination must be specified!| 
    unless (defined $attr->{from} or defined $attr->{to});

  croak qq|Both source and destination may not be specified!| 
    if (defined $attr->{from} and defined $attr->{to});

  # Build paramater list
  my $params = __PACKAGE__->params($attr, [ qw/from 
                                               to 
                                               status 
                                               kind/ ], 1);
  print "PARAMS: $params\n" if $self->{_verbose};

  # Fetch data
  my $content = $self->content({ cmd => q|links|, options => $params });

  my $links = $content->{PHEDEX}{LINK};
  my $info = {};
  for my $link (@$links) {
    my $f = (defined $attr->{to}) ? $link->{FROM} : $link->{TO};
    delete $link->{TO};
    delete $link->{FROM};
    $info->{$f} = $link;
  }
  $self->info($info);
}

1;
__END__
package main;
my $obj = PhEDEx::DataSvc::Links->new({ instance => q|debug| });
my $info = $obj->wget({ from => q|T2_IT_Pisa|, status => q|ok|, kind => q|WAN| });
$obj->show;
