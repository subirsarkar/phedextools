package PhEDEx::DataSvc::Blocks;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use URI::Escape;

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
  croak qq|Either nodename or SE must be specified| 
    unless (defined $attr->{node} or defined $attr->{se});

  my $tmout = $attr->{timeout} || 120;
  # Build parameter list
  my $params = __PACKAGE__->params($attr, [ qw/node 
					       se 
					       update_since 
					       create_since
					       complete
					       subscribed
					       custodial
					       group/ ], 1);
  $params .= defined $attr->{block} 
     ? q|&dataset=| . qq|$attr->{block}| . uri_escape(qq|*|)
     : q||; 
  print "PARAMS: $params\n" if $self->{_verbose};

  # Fetch data
  my $content = $self->content({ cmd => q|blockReplicas|, 
                             options => $params, 
                             timeout => $tmout });

  my $blocks = $content->{PHEDEX}{BLOCK};
  my $info = {};
  for my $block (@$blocks) {
    print join(' ', $block->{NAME}, 
                    $block->{FILES}, 
                    $block->{BYTES}), "\n" if $self->{_verbose};
    $info->{$block->{NAME}} = 
    {
        files => $block->{FILES}, 
        bytes => $block->{BYTES},
      replica => 
      {      
               node => $block->{REPLICA}[0]{NODE},
                 se => $block->{REPLICA}[0]{SE},
              group => $block->{REPLICA}[0]{GROUP} || undef, 
         subscribed => $block->{REPLICA}[0]{SUBSCRIBED},
           complete => $block->{REPLICA}[0]{COMPLETE},
              files => $block->{REPLICA}[0]{FILES},
              bytes => $block->{REPLICA}[0]{BYTES},
          custodial => $block->{REPLICA}[0]{CUSTODIAL},
        time_create => $block->{REPLICA}[0]{TIME_CREATE},
        time_update => $block->{REPLICA}[0]{TIME_UPDATE}
      }
    };
  }
  $self->info($info);
}

1;
__END__
