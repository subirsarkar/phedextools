package PhEDEx::DataSvc::Base;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use PhEDEx::DataSvc::Handler;

sub new
{
  my ($this, $attr) = @_;
  my $class = ref $this || $this;

  my $verbose = $attr->{verbose} || 0;
  bless {
    _baseobj => PhEDEx::DataSvc::Handler->new($attr),
    _verbose => $verbose,
       _info => {}
  }, $class;
}

sub content
{
  my $self = shift;
  my $base = $self->{_baseobj};
  $base->content(@_);
}
sub info
{
  my $self = shift;
  $self->{_info} = shift if @_;
  $self->{_info};  
}

sub show
{
  my $self = shift;
  my $info = $self->info;
  print Data::Dumper->Dump([$info], [qw/$info/]);
}

sub params
{
  my ($pkg, $attr, $tagList, $dflag) = @_;
  $dflag = 1 unless defined $dflag;
  my $params = q||;
  for my $tag (@$tagList)
  {
    $params .= qq|&$tag=$attr->{$tag}| if defined $attr->{$tag};
  }
  # if needed strip the first & char
  $params =~ s/^&// if $dflag>0;
  $params;
}

1;
__END__
