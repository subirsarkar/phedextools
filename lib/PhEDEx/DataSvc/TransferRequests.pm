package PhEDEx::DataSvc::TransferRequests;

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
  for my $tag (qw/request group limit create_since/)
  {
    $params .= qq|&$tag=$attr->{$tag}| if defined $attr->{$tag};
  }
  my $content = $self->content({ cmd => q|groups|, options => $params });
  my $info = {};
  my $list = $content->{PHEDEX}{REQUEST};
  for my $req (@$list) {
    my $datasets = $req->{DATA}{DBS}{DATASET};
    $datasets = $req->{DATA}{DBS}{BLOCK} unless scalar @$datasets;
    for my $dset (@$datasets) {
      my ($dname, $block) = (split /#/, $dset->{NAME});
      $info->{$dname}{dbs}{id}             = $dset->{ID};
      $info->{$dname}{dbs}{files}          = $dset->{FILES} || -1;
      $info->{$dname}{dbs}{bytes}          = $dset->{BYTES} || -1;
      push @{$info->{$dname}{dbs}{blocks}}, $block if defined $block;

      $info->{$dname}{request}{id}         = $req->{ID};
      $info->{$dname}{request}{move}       = $req->{MOVE};
      $info->{$dname}{request}{group}      = $req->{GROUP} || 'undefined';
      $info->{$dname}{request}{priority}   = $req->{PRIORITY};
      $info->{$dname}{request}{custodial}  = $req->{CUSTODIAL};
      $info->{$dname}{request}{static}     = $req->{STATIC};
      $info->{$dname}{request}{time}       = $req->{TIME_CREATE};

      $info->{$dname}{requester}{id}       = $req->{REQUESTED_BY}{ID};
      $info->{$dname}{requester}{name}     = $req->{REQUESTED_BY}{NAME};
      $info->{$dname}{requester}{host}     = $req->{REQUESTED_BY}{HOST};
      $info->{$dname}{requester}{user}     = $req->{REQUESTED_BY}{USERNAME};
      $info->{$dname}{requester}{comments} = $req->{REQUESTED_BY}{COMMENTS}{'$T'};
      $info->{$dname}{requester}{email}    = $req->{REQUESTED_BY}{EMAIL};
      $info->{$dname}{requester}{dn}       = $req->{REQUESTED_BY}{DN} || 'undefined';

      my $nodes = $req->{DESTINATIONS}{NODE};
      for my $node (@$nodes) {
	my $nodename = $node->{NAME};
        my $sename   = $node->{SE};
        my $mynode = 0;
        (defined $self->{_attr}{node} and $nodename eq $self->{_attr}{node}) and $mynode = 1;
        (defined $self->{_attr}{se}   and $sename   eq $self->{_attr}{se})   and $mynode = 1;
        if (defined $node->{DECIDED_BY}{DECISION} and $node->{DECIDED_BY}{DECISION} eq 'y') {
          unless (grep { /$sename/ } @{$info->{$dname}{destination}{selist}}) {
	    push @{$info->{$dname}{destination}{selist}},   $sename;
            push @{$info->{$dname}{destination}{nodelist}}, $nodename;
  	  }
        }
        if ($mynode) {
          $info->{$dname}{approver}{id}       = $node->{DECIDED_BY}{ID};
          $info->{$dname}{approver}{name}     = $node->{DECIDED_BY}{NAME};
          $info->{$dname}{approver}{host}     = $node->{DECIDED_BY}{HOST};
          $info->{$dname}{approver}{user}     = $node->{DECIDED_BY}{USERNAME};
          $info->{$dname}{approver}{dn}       = $node->{DECIDED_BY}{DN};
          $info->{$dname}{approver}{email}    = $node->{DECIDED_BY}{EMAIL};
          $info->{$dname}{approver}{decision} = $node->{DECIDED_BY}{DECISION};
          $info->{$dname}{approver}{time}     = $node->{DECIDED_BY}{TIME_DECIDED};
	}
      }
    }
  }
  $self->info($info);
}

1;
__END__
