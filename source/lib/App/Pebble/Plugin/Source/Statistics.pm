# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Source::Statistics - Statistics source,
i.e. basic statistical transformations.

=cut

package App::Pebble::Plugin::Source::Statistics;
use Moose;

use Method::Signatures;

=head1 METHODS

=head2 percent_of( $what_attribute => ( $attribute | @$attributes ) ) : %percent_attribute_value

Shortcut for turning

  S::Statistics->percent_of( total => [qw/ failures retries /] )

into

  failures_pct  => $_->failures  / ( $_->total || 1 ),
  retries_pct   => $_->retries   / ( $_->total || 1 ),

The naming convention for the new attributes is ${attribute}_pct.

Useful e.g. like this:

  oadd { S::Statistics->percent_of( total => [qw/ failures retries /] ) }

Can also be used with only one attribute

  S::Statistics->percent_of( total => "retries" )

=cut

method percent_of($class: $what_attribute, $percent_of_attributes ) {
  ref $percent_of_attributes eq "ARRAY" or $percent_of_attributes = [ $percent_of_attributes ];

  my $pebble = $_;
  return
    map { ( "${_}_pct"  => $pebble->$_  / ( $pebble->$what_attribute || 1 ) ) }
    @$percent_of_attributes;
}


1;
