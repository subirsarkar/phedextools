package PhEDEx::DataSvc::Groups;

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
  my $params = (defined $attr->{group}) ? qq|group=$attr->{group}| : undef;
  my $content = $self->content({ cmd => q|groups|, options => $params });
  my $info = {};
  my $list = $content->{PHEDEX}{GROUP};
  for my $group (@$list) {
    print join(' ', $group->{NAME} || '?', 
                    $group->{ID} || -1),
        "\n" if $self->{_verbose};
    my $name = delete $group->{NAME};
    $info->{$name}{ID} = $group->{ID};
  }
  $self->info($info);
}

1;
__END__
