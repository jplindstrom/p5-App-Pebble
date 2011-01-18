
=head1 NAME

App::Pebble::Helpers::DateTime - DateTime/Duration helpers.

=head1 DESCRIPTION

Support DateTime and DateTime::Dueration objects "natively" by making
sure they TO_JSON-ify properly.

=cut

package App::Pebble::Helpers::DateTime;

use DateTime;
use DateTime::Duration;

# Needed by Pebble::Object and JSON::XS
sub DateTime::TO_JSON {
    my $self = shift;
    "$self";
}

# Needed by Pebble::Object and JSON::XS
sub DateTime::Duration::TO_JSON {
    my $self = shift;
    ###TODO: replace with format duration
    $self->in_units( "nanoseconds" );
}

1;
