# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Source::String - String utils

=cut

package App::Pebble::Plugin::Source::String;
use Moose;

use Method::Signatures;
use String::Trim;

use App::Pebble::Plugin::Source::Statistics;
use App::Pebble::Modifier::Object;


=head1 METHODS

=head2 otrim( $attribute ) : $pipeline_segment

Return an o {} pipeline segment which trims the whitespace (leading
and trailing) of the value of $attribute.

=cut

method otrim($class: $attribute ) {
    # Validate attribute
    return o { $_->$attribute( trim( $_->$attribute ) ) }
}

=head2 otrim_leading( $attribute ) : $pipeline_segment

Return an o {} pipeline segment which trims the leading whitespace of
the value of $attribute.

=cut

method otrim_leading($class: $attribute ) {
    # Validate attribute
    return o { $_->$attribute( ltrim( $_->$attribute ) ) }
}

=head2 otrim_trailing( $attribute ) : $pipeline_segment

Return an o {} pipeline segment which trims the trailing whitespace of
the value of $attribute.

=cut

method otrim_trailing($class: $attribute ) {
    # Validate attribute
    return o { $_->$attribute( rtrim( $_->$attribute ) ) }
}

1;
