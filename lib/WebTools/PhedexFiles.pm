package WebTools::PhedexFiles;

use strict;
use warnings;
use Carp;

use Data::Dumper;
use LWP::UserAgent;
use URI::Escape;

our $qFormat = qq|https://cmsweb.cern.ch/phedex/datasvc/perl/prod/%s?block=%s|;

sub new
{
  my ($this, $attr) = @_;
  my $class = ref $this || $this;

  croak qq|Neither \$attr->{node} nor \$attr->{se} provided!|
        unless (defined $attr && (exists $attr->{node} or exists $attr->{se}));
  $attr->{verbose}  =   0   unless exists $attr->{verbose};
  $attr->{complete} = 'na'  unless exists $attr->{complete};
  my $self = bless {
    _verbose => $attr->{verbose},
    _complete => $attr->{complete}
  }, $class;
  $self->{_node} = $attr->{node} if exists $attr->{node};
  $self->{_se}   = $attr->{se}   if exists $attr->{se};
  $self;
}

sub _qUpdate
{
  my $self = shift;
  $qFormat .= sprintf qq|&node=%s|, $self->{_node} if exists $self->{_node};
  $qFormat .= sprintf qq|&se=%s|,   $self->{_se}   if exists $self->{_se};
}

sub blocks
{
  my ($self, $dataset) = @_;
  $self->_qUpdate;

  my $blk = {};

  # Instantiate an LWP User Agent to communicate through
  my $agent = LWP::UserAgent->new(timeout => 15);

  my $query = sprintf $qFormat, qq|blockReplicas|, uri_escape(qq|$dataset*|);
  $query .= qq|&complete=$self->{_complete}| if $self->{_complete} ne 'na';
  print "$query\n" if $self->{_verbose};

  my $response = $agent->get($query);
  # query ok, now look inside the Data::Dumper data structure
  if ($response->is_success) {
    my $content = $response->content;
    my $VAR1; eval $content;
    my $blocks = $VAR1->{phedex}{block};
    for my $block (@$blocks) {
      print join(' ', $block->{name}, $block->{files}, $block->{bytes}), "\n" if $self->{_verbose};
      $blk->{$block->{name}} = [$block->{files}, $block->{bytes}];
    }
  }
  else {
    my $status = $response->status_line;
    carp qq|ERROR. query $query failed because: $status|;
  }
  $blk;
}

sub _filelist
{
  my $self = shift;
  $self->_qUpdate;

  $self->{_info} = {};
  # Instantiate an LWP User Agent to communicate through
  my $agent = LWP::UserAgent->new(timeout => 15);

  my $query = sprintf $qFormat, qq|blockReplicas|, uri_escape(qq|*|);
  $query .= qq|&complete=$self->{_complete}| if $self->{_complete} ne 'na';
  print "$query\n" if $self->{_verbose};

  my $response = $agent->get($query);
  # query ok, now look inside the Data::Dumper data structure
  if ($response->is_success) {
    my $content = $response->content;
    my $VAR1; eval $content;
    my $blocks = $VAR1->{phedex}{block};
    for my $block (@$blocks) {
      print join(' ', $block->{name}, $block->{files}), "\n" if $self->{_verbose};

      # escape the offending # character in the blockname string
      my $blockname = $block->{name};
      my ($dataset, $datablock) = split /#/, $blockname;
      $blockname = join uri_escape("#"), $dataset, $datablock;

      # Now retrieve the file replicas for ths block
      $query = sprintf $qFormat, qq|fileReplicas|, qq|$blockname|;
      print "$query\n" if $self->{_verbose};

      $response = $agent->get($query);

      # query ok, now look inside the Data::Dumper data structure
      if ($response->is_success) {   
        $content = $response->content;
        my $VAR1; eval $content;
        my $files = $VAR1->{phedex}{block}[0]{file};
        for my $file (@$files) {
          print join(' ', $file->{name}, $file->{bytes}), "\n" if $self->{_verbose};
          $self->{_info}{$file->{name}} = 
          { 
               size => $file->{bytes}, 
            dataset => $dataset, 
              block => $datablock
          };
        }
      }
      else {
        my $status = $response->status_line;
        carp qq|ERROR. query $query failed because: $status|;
      } 
    }
  }
  else {
    my $status = $response->status_line;
    carp qq|ERROR. query $query failed because: $status|;
  }
}

sub show
{
  my $self = shift;
  my $info = $self->info; # lazy initialization
  print Data::Dumper->Dump([$info], [qw/phedexfiles/]);
}

sub info
{
  my $self = shift;
  $self->_filelist unless exists $self->{_info};
  $self->{_info};
}

1;
__END__
my $files = WebTools::PhedexFiles->new;
$files->show;

# --- Documentation starts
=pod

=head1 NAME

WebTools::PhedexFiles - Queries the PhEDEx data service to prepare a list of files PhEDEx believes a site should have

=head1 SYNOPSIS

  use WebTools::PhedexFiles;
  my $obj = WebTools::PhedexFiles->new;
  $obj->show;

=head1 REQUIRES

  LWP::UserAgent
  URI::Escape
  Data::Dumper

=head1 INHERITANCE

none.

=head1 EXPORTS

none.

=head1 DESCRIPTION

The PhEDEx data service allows one to find all the dataset block and file replicas for each site
that should be available at the site according to PhEDEx. WebTools::PhedexFiles fetches all such information and 
prepares its own data structure with the list of filename as key and blockname, filesize etc. as values for 
each file found on PhEDEx.

=head2 Public methods

=over 4

=item * new ($attr): object reference

Class constructor.

  $attr->{node}     - storage name (e.g T2_IT_Pisa)
  $attr->{se}       - storage name (e.g cmsdcache.pi.infn.it)
  $attr->{verbose}  - debug flag
  $attr->{complete} - if enabled, looks for completed blocks only (values: y|n|na)

=item * show (None): None

Dumps the information collected from the PhEDEx data service,

  print Data::Dumper->Dump([$var], [qw/label/])

However, the above may turn out to be too verbose.

=item * info (None): $info

Returns the underlying container

=back

=cut

#------------------------------------------------------------
#                      Other doc
#------------------------------------------------------------

=pod

=head1 SEE ALSO

dCacheTools::PhedexComparison

=head1 AUTHORS

Subir Sarkar (subir.sarkar@cern.ch)

=head1 COPYRIGHT

This software comes with absolutely no warranty whatsoever.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

$Id: PhedexFiles.pm,v 1.0 2008/06/17 00:03:19 sarkar Exp $

=cut
# ----- Documentation ends
