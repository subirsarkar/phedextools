package PhEDEx::DataSvc::MissingFiles;

use strict;
use warnings;
use Carp;

use base q|PhEDEx::DataSvc::FilesBase|;

sub new
{
  my ($this, $attr) = @_;
  my $class = ref $this || $this;

  my $self = $class->SUPER::new($attr);
  $self->cmd(q|missingfiles|);
  $self->tags([ qw/node 
                   se 
                   subscribed
                   custodial
	           group/ ]);
  bless $self, $class;
}

1;
__END__
package main;
my $obj = PhEDEx::DataSvc::MissingFiles->new;
$obj->wget({      node => q|T2_IT_Pisa|, 
                 block => q|/Cosmics/CRUZET4_v1_CRZT210_V1_TrackerPointing_v1/RECO|,
            subscribed => q|y|
          });
$obj->show;
