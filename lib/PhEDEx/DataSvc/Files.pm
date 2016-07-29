package PhEDEx::DataSvc::Files;

use strict;
use warnings;
use Carp;

use base q|PhEDEx::DataSvc::FilesBase|;

sub new
{
  my ($this, $attr) = @_;
  my $class = ref $this || $this;

  my $self = $class->SUPER::new($attr);
  $self->cmd(q|fileReplicas|);
  $self->tags([ qw/node 
                   se 
                   update_since 
                   create_since
                   complete
                   dist_complete
                   subscribed
                   custodial
	           group/ ]);
  bless $self, $class;
}

1;
__END__
package main;
my $obj = PhEDEx::DataSvc::Files->new({ verbose => 0 });
$obj->wget({  
        node => q|T2_IT_Pisa|, 
       block => qq|/MinBias_TuneD6T_7TeV-pythia6/Spring10-START3X_V26B-v1/GEN-SIM-RECO#6d3dc22e-ea35-414f-b28b-e68bef238cab|,
  subscribed => 'y'
});
$obj->show;
