package WebTools::DataSvc::GroupUsage;

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
  croak qq|Nodename or SE must be specified| 
    unless (defined $attr->{node} or defined $attr->{se});
  my $params = '';
  for my $tag (qw/node 
                  se 
                  group
               /)
  {
    $params .= qq|&$tag=$attr->{$tag}| if defined $attr->{$tag};
  }
  $params =~ s/^&//; 

  my $content = $self->content({ cmd => q|groupusage|, options => $params });
  my $list = $content->{PHEDEX}{NODE}[0]->{GROUP};
  my $info = {};
  for my $group (@$list) {
    print join(' ', $group->{NAME} || '?', 
                    $group->{ID} || -1), 
        "\n" if $self->{_verbose};
    my $name = $group->{NAME};
    $info->{$name}{id}     = $group->{ID};
    $info->{$name}{rbytes} = $group->{NODE_BYTES};
    $info->{$name}{sbytes} = $group->{DEST_BYTES};
    $info->{$name}{rfiles} = $group->{NODE_FILES};
    $info->{$name}{sfiles} = $group->{DEST_FILES};
  }
  $self->info($info);
}

1;
__END__
package main;
my $obj = WebTools::DataSvc::GroupUsage->new;
my $info = $obj->wget({ node => q|T2_IT_Pisa| });
$obj->show;
