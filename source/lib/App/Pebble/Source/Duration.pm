
=head1 NAME

App::Pebble::Source::Duration - Duration source, formatting of
Duration objects.

=head2 DESCRIPTION

L<DateTime::Format::Duration>

=cut

package App::Pebble::Source::Duration;
use Moose;
use MooseX::Method::Signatures;

use DateTime::Format::Duration;

method format($class: $duration, $format) {
    $format ||= "%s";
    return DateTime::Format::Duration->new(
      pattern => $format,
    )->format_duration( $duration );
}

1;
