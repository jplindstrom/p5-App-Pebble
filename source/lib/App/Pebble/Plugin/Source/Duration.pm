
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
use Time::Elapsed qw( elapsed );

method format($class: $duration, $format = "%s") {
    return DateTime::Format::Duration->new(
        pattern => $format,
    )->format_duration( $duration );
}

method human($class: $duration) {
    my $elapsed = elapsed( $class->format( $duration ) );
    $elapsed =~ s/((\d) (\w)\w+)/$2$3/g;
    $elapsed =~ s/ and /, /g;
  
    return $elapsed;
}

1;
