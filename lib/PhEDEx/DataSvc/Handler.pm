package PhEDEx::DataSvc::Handler;

use strict;
use warnings;
use Carp;

use Data::Dumper;
use LWP::UserAgent;
use URI::Escape;

our $_bquery = qq|https://cmsweb.cern.ch/phedex/datasvc/perl|;

sub new
{
  my ($this, $attr) = @_;
  my $class = ref $this || $this;
  bless {
    _instance => $attr->{instance} || q|prod|,
     _verbose => $attr->{verbose} || 0,
       _agent => LWP::UserAgent->new (ssl_opts => { verify_hostname => 0 })
  }, $class;
}
sub content
{
  my ($self, $attr) = @_;
  croak qq|Command not specified!| unless defined $attr->{cmd};
  my $cmd     = $attr->{cmd};
  my $tmout   = $attr->{timeout} || 20;
  my $options = $attr->{options} || undef;
  my $verbose = $attr->{verbose} || 0;

  my $instance = $self->{_instance};
  my $query = sprintf qq|$_bquery/$instance/$cmd|;
  $query .= qq|?$options| if (defined $options and length $options);
  print "QUERY: $query\n" if $self->{_verbose};

  # get back the LWP::UserAgent object
  my $agent = $self->{_agent};
  $agent->timeout($tmout);
  my $response = $agent->get($query);

  # query ok, now look inside the Data::Dumper data structure
  unless ($response->is_success) {
    carp qq|>>> ERROR. query $query failed because: | . $response->status_line;
    return undef;
  }
  # return the data strcuture
  my $content = $response->content;
  my $VAR1; eval $content;
  $VAR1;
}

1;
__END__
package main;

my $req = PhEDEx::DataSvc::Handler->new;
my $content = $req->content({ cmd => q|nodes| });
print Data::Dumper->Dump([$content], [qw/nodes/]);
