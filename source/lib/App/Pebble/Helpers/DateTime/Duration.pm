
=head1 NAME

App::Pebble::Helpers::DateTime::Duration - DateTime::Duration helpers.

=head1 DESCRIPTION

Support DateTime::Duration "natively" by making sure they TO_JSON-ify
properly, and provide some useful extra helper methods.

=cut

package App::Pebble::Helpers::DateTime::Duration;
use strict;
use warnings;
use Method::Signatures;

use DateTime::Duration;
use DateTime::Format::Duration;
use Time::Elapsed qw( elapsed );

no warnings "redefine";

=head2 METHODS

=cut

# Needed by Pebble::Object and JSON::XS
sub DateTime::Duration::TO_JSON {
    my $self = shift;
    ###TODO: replace with format duration
    $self->in_units( "nanoseconds" );
}

=head2 DateTime::Duration::format( $format = "%s" ) : $formatted_string

Return a formatted (in $format) string of the duration, using
L<DateTime::Format::Duration>. Refer to that module for formatting
options.

Default: duration in seconds.

=cut

method DateTime::Duration::format($format = "%s") {
    return DateTime::Format::Duration->new(
        pattern => $format,
    )->format_duration( $self );
}

=head2 DateTime::Duration::human() : $human_redable_string

Return a human-readable string, e.g. "8h, 2m, 24s".

=cut

method DateTime::Duration::human() {
    my $elapsed = elapsed( $self->format() );

    $elapsed =~ s/((\d) (\w)\w+)/$2$3/g; # Shorten unit names from seconds to s
    $elapsed =~ s/ and /, /g;            # always use ,
  
    return $elapsed;
}

1;
