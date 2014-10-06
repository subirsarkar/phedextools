package WebTools::Page;

use strict;
use warnings;
use Carp;

use LWP 5.64;
use URI;
use HTML::TableExtract;

sub Content
{
   my ($pkg, $url, $debug, $params) = @_;
   $debug = 0 unless defined $debug;

   # makes an object representing the URL
   my $ua = new LWP::UserAgent;
   $ua->timeout(20);

   if (defined $params) {
     $url .= qq[?];
     for my $key (sort keys %$params) {
       $url .= qq[&].$key.qq[=].$params->{$key};
     }
     $url =~ s/\&//;
   }

   my $content = '';
   my $uriObj = new URI($url);
   my $response;
   eval {
     $response = $ua->get($uriObj);
   };
   if ($@) {
     carp qq|WebTools::Page::Content. Site $url unavailable!, $@|;
     return $content;
   }
   unless ($response->is_success) {
     carp qq|WebTools::Page::Content. Failed to fetch $url -- |, $response->status_line;
     return $content;
   }

   $content = $response->content;
   print STDERR $content if $debug;
   carp qq|INFO. No information found!| unless length($content);

   $content;
}

sub Table
{
  my ($pkg, $params) = @_;
  die qq|Must specify the url, stopped| unless (defined $params && exists $params->{url});
  $params->{depth}   = 0 unless exists $params->{depth};
  $params->{count}   = 0 unless exists $params->{count};
  $params->{gridmap} = 0 unless exists $params->{gridmap};
  my $query = $params->{url};

  my $h = [];
  my $agent = new LWP::UserAgent(timeout => 15);
  my $response = $agent->get($query);
  if ($response->is_success) {
    my $content = $response->content;
    my $te = new HTML::TableExtract( depth => $params->{depth}, 
                                     count => $params->{count}, 
                                   gridmap => $params->{gridmap}, 
                                 keep_html => 1);
    $te->parse($content);

    foreach my $ts ($te->table_states) {
      foreach my $row ($ts->rows) {
        push @$h, $row;
      }
    }
  }
  else {
    my $status = $response->status_line;
    carp qq|ERROR. query $query failed because: $status|;
  }
  $h;
}

1;
__END__

package main;

my $url = qq|http://cmsdcache:2288/context/transfers.html|;
my $content = WebTools::Page->Content($url, 0);
print $content;
print "\n";

# --- Documentation starts
=pod

=head1 NAME

WebTools::Page - Utility module that has functions to (1) fetch a webpage (2) extract a table embedded in a page

=head1 SYNOPSIS

  use WebTools::Page;

  my $query = qq|http://cmsdcache:2288/queueInfo|;
  my $content = WebTools::Page->Content($query);
  my $rows = WebTools::Page->Table({ url => $query });

=head1 REQUIRES

  LWP 5.64
  URI
  HTML::TableExtract

=head1 INHERITANCE

none.

=head1 EXPORTS

none.

=head1 DESCRIPTION

A collection of module level funtions to fetch web pages in its entirety, extract an embedded table etc.

=head2 Public methods

=over 4

=item * Content ($pkg, $url, $debug, $params): $content

Fetch a web page as a string.

  $pkg - this package
  $url - The webpage to fetch
  $debug - debug flag
  $params - key/value pair in case the url requires parameters

=item * Table ($pkg, $params): @rows

Extract a table embedded in a web page as an array of row objects(TD).

  $pkg    - this package
  $params - specify the table coordinates like depth, count, gridmap etc. that can
            uniquely indentify a table. This is required by HTML::TableExtract

=back

=cut

#------------------------------------------------------------
#                      Other doc
#------------------------------------------------------------

=pod

=head1 SEE ALSO

dCacheTools::QueueInfo, dCacheTools::ActiveTransfers

=head1 AUTHORS

Subir Sarkar (subir.sarkar@cern.ch)

=head1 COPYRIGHT

This software comes with absolutely no warranty whatsoever.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

$Id: Page.pm,v 1.0 2008/06/17 00:03:19 sarkar Exp $

=cut
# ----- Documentation ends

