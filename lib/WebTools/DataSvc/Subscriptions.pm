package WebTools::DataSvc::Subscriptions;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use URI::Escape;

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

  my $tmout = $attr->{timeout} || 120;

  my $params = qq|block=|.(defined $attr->{block} ? qq|$attr->{block}| : '');
  $params .= uri_escape(qq|*|) . __PACKAGE__->params($attr, ['node', 
                                                             'se', 
                                                             'update_since', 
                                                             'create_since',
                                                             'complete',
                                                             'subscribed',
                                                             'custodial',
                                                             'group'], 0);
  print "PARAMS: $params\n" if $self->{_verbose};
  my $content = $self->content({ 
        cmd => q|subscriptions|, 
    options => $params, 
    timeout => $tmout,
    verbose => $self->{_verbose} 
  });
  my $info = {};

  my $list = $content->{PHEDEX}{DATASET};
  for my $d (@$list) {
    print join(' ', $d->{NAME}, 
                    $d->{FILES}, 
                    $d->{BYTES}), "\n" if $self->{_verbose};
    $info->{$d->{NAME}} = 
    {
           id => $d->{ID},
        files => $d->{FILES}, 
        bytes => $d->{BYTES},
      is_open => $d->{IS_OPEN}
    };
    if (exists $d->{BLOCK}) {
      my $blocks = $d->{BLOCK};
      for my $b (@$blocks) {
        push @{$info->{$d->{NAME}}{blocks}},
        {
                    id => $b->{ID},
                  name => $b->{NAME},
                 files => $b->{FILES}, 
                 bytes => $b->{BYTES},
               is_open => $b->{IS_OPEN},
          subscription => 
          {
                   request => $b->{SUBSCRIPTION}[0]{REQUEST},
                     group => $b->{SUBSCRIPTION}[0]{GROUP} || undef, 
                      node => $b->{SUBSCRIPTION}[0]{NODE},
                      move => $b->{SUBSCRIPTION}[0]{MOVE},
             suspend_until => $b->{SUBSCRIPTION}[0]{SUSPEND_UNTIL},
                 custodial => $b->{SUBSCRIPTION}[0]{CUSTODIAL},
                 suspended => $b->{SUBSCRIPTION}[0]{SUSPENDED},
                  priority => $b->{SUBSCRIPTION}[0]{PRIORITY},
                     level => $b->{SUBSCRIPTION}[0]{LEVEL},
               time_create => $b->{SUBSCRIPTION}[0]{TIME_CREATE},
               time_update => $b->{SUBSCRIPTION}[0]{TIME_UPDATE}
          }   
        }        
      }
    }
    else {
      $info->{$d->{NAME}}{blocks} = undef;
      $info->{$d->{NAME}}{subscription} = 
      {
                request => $d->{SUBSCRIPTION}[0]{REQUEST},
                  group => $d->{SUBSCRIPTION}[0]{GROUP} || undef, 
                   node => $d->{SUBSCRIPTION}[0]{NODE},
                   move => $d->{SUBSCRIPTION}[0]{MOVE},
          suspend_until => $d->{SUBSCRIPTION}[0]{SUSPEND_UNTIL},
              custodial => $d->{SUBSCRIPTION}[0]{CUSTODIAL},
              suspended => $d->{SUBSCRIPTION}[0]{SUSPENDED},
               priority => $d->{SUBSCRIPTION}[0]{PRIORITY},
                  level => $d->{SUBSCRIPTION}[0]{LEVEL},
            time_create => $d->{SUBSCRIPTION}[0]{TIME_CREATE},
            time_update => $d->{SUBSCRIPTION}[0]{TIME_UPDATE}
      };
    }
  }
  $self->info($info);
}

1;
__END__
