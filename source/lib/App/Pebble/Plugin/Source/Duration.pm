
=head1 NAME

App::Pebble::Plugin::Source::Duration - Duration source, formatting of
Duration objects.

=head2 DESCRIPTION

L<DateTime::Format::Duration>

=cut

package App::Pebble::Plugin::Source::Duration;
use Moose;
use Method::Signatures;

use DateTime::Format::Duration;

method format($class: $duration, $format = "%s") {
    return DateTime::Format::Duration->new(
      pattern => $format,
    )->format_duration( $duration );
}

1;
