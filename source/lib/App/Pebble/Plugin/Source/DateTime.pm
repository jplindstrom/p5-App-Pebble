
=head1 NAME

App::Pebble::Plugin::Source::DateTime - Date/time source, i.e. parsing
of strings into DateTime objects.

=cut

package App::Pebble::Plugin::Source::DateTime;
use Moose;
use Method::Signatures;

use DateTimeX::Easy;

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

method parse($class: $dt_string) {
    return DateTimeX::Easy->new( $dt_string );
}

method parse_iso($class: $dt_string) {
    $dt_string =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/ or return undef;
    return DateTime->new(
        year   => $1,
        month  => $2,
        day    => $3,
        hour   => $4,
        minute => $5,
        second => $6,
    );
}

1;
