
=head1 NAME

App::Pebble::Helpers::DateTime - DateTime helpers.

=head1 DESCRIPTION

Support DateTime objects "natively" by making sure they TO_JSON-ify
properly, and provide some useful helper methods.

=cut

package App::Pebble::Helpers::DateTime;
use strict;
use warnings;

use DateTime;
use Carp;

=head2 METHODS

=cut

# Needed by Pebble::Object and JSON::XS
sub DateTime::TO_JSON {
    my $self = shift;
    "$self";
}

=head2 DateTime::round( $to_unit = "day" ) : $self

Round off the datetime $to_unit ( "year" | "month" | "day" | "hour" |
"minute" | "second" ) by setting the smaller units to 0 (e.g. minutes)
or 1 (e.g. month).

Change the object in-place.

Note: This should be ported into DateTime proper. It's just here for
now to provide a convenience function.

=cut

my $to_unit_0 = {
    year => {
        month      => 1,
        day        => 1,
        hour       => 0,
        minute     => 0,
        second     => 0,
        nanosecond => 0,
    },
    month => {
        day        => 1,
        hour       => 0,
        minute     => 0,
        second     => 0,
        nanosecond => 0,
    },
    day => {
        hour       => 0,
        minute     => 0,
        second     => 0,
        nanosecond => 0,
    },
    hour => {
        minute     => 0,
        second     => 0,
        nanosecond => 0,
    },
    minute => {
        second     => 0,
        nanosecond => 0,
    },
    second => {
        nanosecond => 0,
    },
};

no warnings "redefine";
sub DateTime::round {
    my $self = shift;
    my ($to_unit) = @_;
    $to_unit ||= "day";

    my $unit_0 = $to_unit_0->{ $to_unit }
        or croak( "Invalid \$to_unit ($to_unit) in call to DateTime->round(\$to_unit)" );
        
    $self->set( %$unit_0 );
    return $self;
}

1;
